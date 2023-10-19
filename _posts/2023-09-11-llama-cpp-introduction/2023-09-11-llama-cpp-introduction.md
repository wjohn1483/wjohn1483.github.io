---
title: 如何使用CPU跑LLM
tags: Tool Machine-Learning Natural-Language-Processing
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

Large Language Model（LLM）的風潮席捲全球，大家都在努力嘗試使用LLM來建造各式各樣的應用，但LLM本身所需要的計算量很大，沒有足夠的資源是跑不起來的，好在網路上有很多大神們在嘗試只使用少量的把LLM給跑起來，這篇文章介紹一下如何使用CPU的資源就將Llama2跑起來。

<!--more-->

## GGML

現在把LLM跑在資源相較匱乏的電腦上的方法主要都是透過quantization來減少模型的計算量，在訓練模型的時候，模型通常都是使用32 bits的浮點數來去儲存參數，倘若我們把浮點數下調一些，用16 bits或是4bits來儲存的話，雖說計算的精準度會下降，但模型在inference的計算量就可以減少很多。

其中quantization最常使用的是[ggml](https://github.com/ggerganov/ggml)這個工具，ggml是個用C寫成的套件，它可以幫助你把手上的模型做quantization，而且支援目前大多數的開源LLM模型，支援的模型們可以去它的github上面看。

## llama.cpp

[llama.cpp](https://github.com/ggerganov/llama.cpp)是一個基於ggml的工具，讓你可以很輕易地把你手上建構在llama上的模型做quantization，像是Llama、Alpaca、Vicuna、Llama2等都可以透過llama.cpp來把模型變得更小、計算得更快，底下會講一下如何使用llama.cpp來讓Llama2跑在CPU上。

### Llama2

[Llama2](https://ai.meta.com/llama/)是Meta基於Llama訓練出來的有條件可商用模型，如果想要取得Llama2的模型，可以直接去Meta的官網上面填寫資料，之後根據寄來的email上的指示就能將模型的參數們下載回來了。

```bash
-> % ls llama-2-13b-chat
checklist.chk  consolidated.00.pth  consolidated.01.pth  params.json  tokenizer.model
```

### Compile llama.cpp

在quantize模型之前，我們需要先編譯一下我們的工具llama.cpp，編譯的方法可以參考github上的[README.md](https://github.com/ggerganov/llama.cpp#readme)，如果是Linux的話應該只需要將repository clone下來以後執行make就可以了。

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
pip3 install -r requirements.txt
make
```

### Quantization

接下來就可以著手來做quantization了，詳細的步驟也可以參考[官方的README.md](https://github.com/ggerganov/llama.cpp#prepare-data--run)，首先我們需要將模型的參數做成16 bits的gguf檔，在過去被稱為ggml，也就是套件的名稱，但後來ggml的格式又做了一些修改，變成了gguf，獲得了更好的可擴充性。

```bash
python3 ./convert.py ~/llama-2-13b-chat/
```

這時在原本模型儲存的路徑下應該會多出一個**ggml-model-f16.gguf**檔，這時其實就可以使用這個比較小的模型檔來在CPU上面做inference了，不過我們還可以進一步的做quantization，來讓執行時間變得更短。

```bash
./quantize ~/llama-2-13b-chat/ggml-model-f16.gguf ~/llama-2-13b-chat/ggml-model-f16.gguf.q4_0.bin q4_0
```

在上面的指令裡面，我們給了3個參數，分別是剛剛做好的gguf檔，再來是做完quantization後想輸出的路徑，最後是quantization的方法，quantization的方法在[README.md](https://github.com/ggerganov/llama.cpp#quantization)上面有列表來告訴我們有哪些選項，以及其效果如何。

在[Hugging Face上](https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF)也已經有別人quantized好的模型了，如果想直接拿現成的也可以從上面下載下來。

### Inference

在quantize好自己想要的大小的模型以後，接下來就是使用這個模型來執行看看prompt了。

```bash
./main -m ~/llama-2-13b-chat/ggml-model-f16.gguf.q4_0.bin -n -1 -e -t 8 -p "YOUR PROMPT HERE"
```

關於`main`更多的參數可以透過`./main -h`來查看，這邊列一下上面指令option所代表的意思。

```bash
  -m FNAME, --model FNAME
                        model path (default: models/7B/ggml-model-f16.gguf)
  -n N, --n-predict N   number of tokens to predict (default: -1, -1 = infinity, -2 = until context filled)
  -t N, --threads N     number of threads to use during computation (default: 4)
  -p PROMPT, --prompt PROMPT
                        prompt to start generation with (default: empty)
  -e, --escape          process prompt escapes sequences (\n, \r, \t, \', \", \\)
```

如果我們想要透過python使用這個quantized好的模型，我們可以使用[llama-cpp-python](https://github.com/abetlen/llama-cpp-python)，能過直接透過pip來安裝。

```bash
pip install llama-cpp-python
```

接著就能使用類似下面的程式碼來使用了，更多的使用方法可以參考其github repository。

```python
from llama_cpp import Llama
llm = Llama(model_path="./llama-2-13b-chat/ggml-model-f16.gguf.q4_0.bin")
output = llm("YOUR PROMPT HERE", max_tokens=128, echo=True)
print(output)
```

值得一提的是，它所回傳的會是一個類似底下的dict object，需要自己再parse一下。

```json
{
  "id": "cmpl-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "object": "text_completion",
  "created": 1679561337,
  "model": "./models/7B/ggml-model.bin",
  "choices": [
    {
      "text": "Q: Name the planets in the solar system? A: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune and Pluto.",
      "index": 0,
      "logprobs": None,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 14,
    "completion_tokens": 28,
    "total_tokens": 42
  }
}
```

## GPU Acceleration

如果你希望能把已經quantized好的模型，加速跑得更快的話，可以考慮在`pip install llama-cpp-python`的時候，多加一些參數，讓它可以使用各種[BLAS](https://zh.wikipedia.org/zh-tw/BLAS) backend來加速，如果你安裝的是cuBLAS，還可以使用GPU的資源來加速，詳細的介紹可以參考[README.md](https://github.com/abetlen/llama-cpp-python#installation-with-hardware-acceleration)，下面放上使用cuBLAS的安裝指令。

```bash
export LLAMA_CUBLAS=1
CMAKE_ARGS="-DLLAMA_CUBLAS=on" FORCE_CMAKE=1 pip install --upgrade --force-reinstall llama-cpp-python --no-cache-dir
```

這時我們在使用llama-cpp-python的時候，就能於讀取模型的地方多加`n_gpu_layers`的參數把部分的模型放到GPU上面執行。

```python
from llama_cpp import Llama
llm = Llama(model_path="./llama-2-13b-chat/ggml-model-f16.gguf", verbose=True, n_gpu_layers=43)
output = llm("YOUR PROMPT HERE", max_tokens=128, echo=False, temperature=0.8)
print(output)
```

不同的模型、不同quantized的參數產生的模型所需要的GPU記憶體都不同，需要試著跑看看才知道GPU能不能吃的下來，而模型總共有多少layer可以在llama-cpp-python寫出來的log裡面看到，像是llama2總共有43層，`n_gpu_layers`設定超過43跟設43是一樣的效果。

### GPTQ

上面所使用的quantization方法主要是調整模型參數的bit數，來達到減少運算量的目標，但這樣直接減少bit的數目會對精準度有一些影響，所以就有人在研究怎麼在quantize某一個特定的參數時，適時地調整還沒有被quantize的其他參數，讓整體的loss與quantize前的不要差異太大，其中衍生出了很多方法及其演進（OBD→OBS→OBQ→GPTQ），詳細的介紹和背後的原理推薦看[QLoRA、GPTQ：模型量化概述](https://zhuanlan.zhihu.com/p/646210009)這篇文章的介紹。

在[HuggingFace上](https://huggingface.co/TheBloke/Llama-2-7b-Chat-GPTQ)，有人使用了GPTQ的技術對Llama2做quantization，並將算出來的模型參數放上去了，如果對上面使用llama.cpp做出來的模型不滿意，且有個不錯的GPU，可以試試看用GPTQ quantize的Llama2。

## 參考資料

* [GPTQ: 模型量化，穷鬼救星](https://zhuanlan.zhihu.com/p/616969812)
* [QLoRA、GPTQ：模型量化概述](https://zhuanlan.zhihu.com/p/646210009)
