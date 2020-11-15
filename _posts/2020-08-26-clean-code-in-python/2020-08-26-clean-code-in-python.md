---
title: Clean Code In Python
tags: Book Python
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
published: true
---
Clean code in python sharing.

<!--more-->

## Chapter 5: Decorater

### What is decorator

```python
@modifier   # This is decorator
def original(...):
```

```python
original = modifier(original)
```

Calling whatever is after the decorator as a first parameter, and the result would be whatever the decorator returns.

### Decorate functions

```python
def retry(operation):
    @wraps(operation)  # Please ignore this line for now
    def wrapped(*args, **kwargs):
        last_raised = None
    	RETRIES_LIMIT = 3
        for _ in range(RETRIES_LIMIT):
    	    try:
                return operation(*args, **kwargs)
            except ControlledException as e:
                logger.info("Retrying %s", operation.__qualname__)
                last_raised = e
        raise last_raised
    
    return wrapped


@retry
def run_operation(task):
    return task.run()


run_operation = retry(run_operation)  # function definition
run_operation(task)  # function call
```

### Decorate classes

```python
class LoginEventSerializer:
    def __init__(self, event):
        self.event = event

    def serialize(self) -> dict:
        return {
            "username": self.event.username,
            "password": "**redacted**",
            "ip": self.event.ip,
            "timestamp": self.event.timestamp.strftime("%Y-%m-%d %H:%M"),
        }


class LoginEvent:
    SERIALIZER = LoginEventSerializer

    def __init__(self, username, password, ip, timestamp):
        self.username = username
        self.password = password
        self.ip = ip
        self.timestamp = timestamp

    def serialize(self) -> dict:
        return self.SERIALIZER(self).serialize()
```

Some drawbacks:

* **Too many classes**: number of serialization classes will grow in the same order of magnitude because they are mapped one to one.

* **The solution is not flexible enough**: If we need to reuse parts of components(e.g. hide *password*), we will have to extract as a function and call it repeatedly from mutiple classes.

* **Boilerplate**: The `serialize()`method will have to be present in all `event` classes, calling the same code.

> Dynamically contruct an object by given a set of transformation functions.
>
> We then only need to define the functions to transform each type of field.

```python
def hide_field(field) -> str:
    return "**redacted**"


def format_time(field_timestamp: datetime) -> str:
    return field_timestamp.strftime("%y-%m-%d %H:%M")


def show_original(event_field):
    return event_field


class EventSerializer:
    def __init__(self, serialization_fields: dict) -> None:
        self.serialization_fields = serialization_fields
        
    def serialize(self, event) -> dict:
        return {
            field: transformation(getattr(event, field))
            for field, transformation in
            self.serialization_fields.itmes()
        }
    
    
class Serialization:
    def __init__(self, **transformations):
        self.serializer = EventSerializer(transformations)
    
    def __call__(self, event_class):
        def serialize_method(event_instance):
            return self.serializer.serialize(event_instance)
        event_class.serialize = serialize_method
        return event_class
    

@Serialization(
    username=show_original,
    password=hide_field,
    ip=show_original,
    timestamp=format_time,
)
class LoginEvent:
    def __init__(self, username, password, ip, timestamp):
        self.username = username
        self.password = password
        self.ip = ip
        self.timestamp = timestamp
```

```python
# In Python 3.7+
from dataclasses import dataclass
from datetime import datetime

@Serialization(
    username=show_original,
    password=hide_field,
    ip=show_original,
    timestamp=format_time,
)
@dataclass
class LoginEvent:
    username: str
    password: str
    ip: str
    timestamp: datetime
```

Decorator makes it easier for the user to know how each field is going to be treated without having to look into the code of another class.

The code of the class does not need `serialize()` method defined, decorator will add it.

### Passing arguments to decorators

#### Decorators with nested functions

```python
RETRIES_LIMIT=3


def with_retry(retries_limit=RETRIES_LIMIT, allowed_exceptions=None):
    allowed_exceptions = allowed_exceptions or (ControlledException,)
    
    def retry(operation):
        @wraps(operation)
        def wrapped(*args, **kwargs):
            last_raised = None
            for _ in range(retries_limit):
                try:
                    return operation(*args, **kwargs)
                except allowed_exceptions as e:
                    logger.info("retrying %s due to %s", operation, s)
                    last_raised = e
            raise last_raised
        return wrapped
    
    return retry
```

```python
@with_retry()
def run_operation(task):
    return task.run()


@with_retry(retries_limit=5)
def run_with_custom_retries_limit(task):
    return task.run()


@with_retry(allowed_exceptions=(AttributeError,))
def run_with_custom_exceptions(task):
    return task.run()


@with_retry(retries_limit=4, allowed_exceptions=(ZeroDivisionError, AttributeError))
def run_with_custom_parameters(task):
    return task.run()
```

```python
@with_retry(retries_limit=4, allowed_exceptions=(ZeroDivisionError, AttributeError))
def run_with_custom_parameters(task):
    return task.run()


@retry
def run_with_custom_parameters(task):
    return task.run()


run_with_custom_parameters = retry(run_with_custom_parameters)
run_with_custom_parameters(task)
```

#### Decorator objects

```python
class WithRetry:
    def __init__(self, retries_limit=RETRIES_LIMIT, allowed_exceptions=None):
        self.retries_limit = retries_limit
        self.allowed_exceptions = allowed_exceptions or (ControlledException,)
        
    def __call__(self, operation):
        @wraps(operation)
        def wrapped(*args, **kwargs):
            last_raised = None
            
            for _ in range(self.retries_limit):
                try:
                    return operation(*args, **kwargs)
                except self.allowed_exceptions as e:
                    logger.info("retrying %s due to %s", operation, e)
                    last_raised = e
            raise last_raised
            
        return wrapped
```

```python
@WithRetry(retries_limit=5)
def run_with_custom_retries_limit(task):
    return task.run()
```

Invoke order:

1. `WithRetry(retries_limit=5)` , an object is created
2. `@` is invoked, `run_with_custom_retries_limit = WithRetry(retries_limit=5)(run_with_custom_retries_limit)`
3. `call()` is invoked

### Good uses for decorators

* Transforming parameters
* Validate parameters
* Implement retry operations
* Tracing code
* Simplify classes by moving some logic into decorators

### Effective decorators - avoiding common mistakes

#### Preserving data about the original wrapped object

```python
def trace_decorator(function):
    # NO @wraps HERE!
    def wrapped(*args, **kwargs):
        logger.info("running %s", function.__qualname__)
        return function(*args, **kwargs)
    
    return wrapped
```

```python
@trace_decorator
def process_account(account_id):
    """Process an account by Id"""
    logger.info("processing account %s", account_id)
    ...
```

```python
In [3]: help(process_account)
Help on function wrapped in module __main__:

wrapped(*args, **kwargs)


In [4]: process_account.__qualname__
Out[4]: 'trace_decorator.<locals>.wrapped'

```

```python
In [8]: from functools import wraps

In [9]: def trace_decorator(function):
   ...:     @wraps(function)
   ...:     def wrapped(*args, **kwargs):
   ...:         print(f"running {function.__qualname__}")
   ...:         return function(*args, **kwargs)
   ...:     return wrapped
   ...:

In [10]: @trace_decorator
    ...: def process_account(account_id):
    ...:     """Process an account by Id."""
    ...:     print(f"processing account {account_id}")
    ...:

In [11]: help(process_account)
Help on function process_account in module __main__:

process_account(account_id)
    Process an account by Id.


In [12]: process_account.__qualname__
Out[12]: 'process_account'
```

> Always use **functools.wraps** applied over the wrapped function, when creating a decorator, as shown in the proceding formula.

### Dealing with side-effects in decorators

#### Incorrect handling of side-effects in a decorator

```python
def traced_function_wrong(function):
    logger.info("started execution of %s", function)
    start_time = time.time()
    
    @functools.wraps(function)
    def wrapped(*args, **kwargs):
        result = function(*args, **kwargs)
        logger.info(
            "function %s took %.2fs",
            function,
            time.time() - start_time
        )
        return result
    return wrapped


@traced_function_wrong
def process_with_delay(callback, delay=0):
    time.sleep(delay)
    return callback()
```

```python
In [7]: process_with_delay()
INFO:root:function <function process_with_delay at 0x107d35a60> took 10.66s

In [8]: process_with_delay()
INFO:root:function <function process_with_delay at 0x107d35a60> took 12.24s

In [9]: process_with_delay()
INFO:root:function <function process_with_delay at 0x107d35a60> took 12.97s
```

```python
process_with_delay = traced_function_wrong(process_with_delay)
```

```python
def traced_function_wrong(function):
    @functools.wraps(function)
    def wrapped(*args, **kwargs):
        logger.info("started execution of %s", function)
        start_time = time.time()
        result = function(*args, **kwargs)
        logger.info(
            "function %s took %.2fs",
            function,
            time.time() - start_time
        )
        return result
    return wrapped
```

#### Requiring decorators with side-effects

```python
# user_event.py
EVENTS_REGISTRY = {}


def register_event(event_cls):
    """Place the class for the event into the registry to make it accesible in the 
    module.
    """
    EVENTS_REGISTRY(event_cls.__name__) = event_cls
    return event_cls


class Event:
    """A base event object"""
    

class UserEvent:
    TYPE = "user"
    
    
@register_event
class UserLoginEvent(UserEvent):
    """Represents the event of a user when it has just accessed the system."""
   

@register_event
class UserLogoutEvent(UserEvent):
    """Event triggered right after a user abandoned the system."""
```

```python
In [1]: from user_event import EVENTS_REGISTRY

In [2]: EVENTS_REGISTRY
Out[2]:
{'UserLoginEvent': user_event.UserLoginEvent,
 'UserLogoutEvent': user_event.UserLogoutEvent}
```

### Createing decorators that will always work

```python
class DBDriver:
    def __init__(self, dbstring):
        self.dbstring = dbstring
    
    def execute(self, query):
        return f"query {query} at {self.dbstring}"
    

def inject_db_driver(function):
    """"This decorator converts the parameter by creating a ``DBDriver`` instance from the 
    database dsn string.
    """
    @wraps(function)
    def wrapped(dbstring):
        return function(DBDriver(dbstring))
    return wrapped


@inject_db_driver
def run_query(driver):
    return driver.execute("test_function")
```

```python
In [6]: run_query("test_OK")
Out[6]: 'query test_function at test_OK'
```

```python
class DataHandler:
    @inject_db_driver
    def run_query(self, driver):
        return driver.execute(self.__class__.__name__)
```

```python
In [8]: DataHandler().run_query("test_fails")
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-8-33911e5917dd> in <module>
----> 1 DataHandler().run_query("test_fails")

TypeError: wrapped() takes 1 positional argument but 2 were given
```

```python
from functools import wraps
from types import MethodType


class inject_db_driver:
    """Convert a string to a DBDriver instance and pass this to the wrapeed function."""
    
    def __init__(self, function):
        self.function = function
        wraps(self.function)(self)
    
    def __call__(self, dbstring):
        return self.function(DBDriver(dbstring))
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return self.__class__(MethodType(self.function, instance))
```

Will be explained in Chapter 6.

### The DRY(Don't Repeat Yourself) principle with decorators

Any decorator (especially if it is not carefully designed) adds another level of indirection to the code.

If there is not going to be too much reuse, then do not go for a decorator and opt for a simpler option (maybe just a separate function or another small class ie enough).

* Do not create the decorator in the first place from scratch. Wait until the pattern emerges and the abstraction for the decorator becomes clear, and then refactor.
* Consider that the decorator has to be applied several times (at least three times) before implementing it.
* Keep the code in the decorators to a minimum

### Decorators and separation of concerns

```python
def traced_function_wrong(function):
    @functools.wraps(function)
    def wrapped(*args, **kwargs):
        logger.info("started execution of %s", function)
        start_time = time.time()
        result = function(*args, **kwargs)
        logger.info(
            "function %s took %.2fs",
            function,
            time.time() - start_time
        )
        return result
    return wrapped
```

Carrying two responsibilities: logs that a particular function was just invoked and logs how much time it took to run.

```python
def log_execution(function):
    @wraps(function)
    def wrapped(*args, **kwargs):
        logger.info("started execution of %s", function.__qualname__)
        return function(*args, **kwargs)
    return wrapped


def measure_time(function):
    @wraps(function)
    def wrapped(*args, **kwargs):
        start_time = time.time()
        result = function(*args, **kwargs)
        logger.info("function %s took %.2f", function.__qualname__, time.time()-start_time)
        return result
    return wrapped


@measure_time
@log_execution
def operation():
    ...
```

> Do not place more than one responsibility in a decorator. The SRP applies to decorators as well.

### Analyzing good decorators

Good decorators should have:

* **Encapsulation, or separation of concerns**: A good decorator should effectively separate different responsibilities between what it does and what it is decorating.
* **Orthogonality**: What the decorator does should be independent, and as decoupled as possible from the object it is decorating.
* **Reusability**: It is desirable that the decorator can be applied to multiple types, and not that it just appears on one instance of one function, because that means that it could just have been a function instead.

#### Good examples

```python
# From Celery project
@app.task
def mytask():
    ...
    

# From web frameworks (Pyramid, Flask, etc)
@route("/", method=["GET"])
def view_handler(request):
    ...
```

User only needs to define the function body and the decorator will convert that into a task automatically.

The `@app.task` decorator surely wraps a lot of logic and code, but none of that is relevant to the body of `mytask()`.

A good decorator should provide a clean interface so that users of the code know what to expect from the decorator, without needing to know how it works, or any of its details for that matter.

### Summary

Decorators are powerful tools in Python that can be applied to many things.

When creating a decorator for functions, try to make its signature match the original function being decorated. Instead of using the generic `*args` and `**kwargs`, making the signature match the original one willl make it easier to read and maintain.

