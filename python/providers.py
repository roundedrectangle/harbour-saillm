# pyright: reportImplicitOverride=false
from openai.types.chat import ChatCompletionChunk
from pyotherside import send as qsend
from provider_abc import Provider
from utils import *
from enum import Enum
from typing import Optional, Type
from openai import OpenAI
from ollama import Client as Ollama
import ollama._types, httpx
import json

__all__ = ['Provider', 'ProviderMapping', 'OpenAIProvider', 'OllamaProvider']

class ProviderMapping(Enum):
    unset = 0
    ollama = 1
    openai = 2

    @property
    def implementation(self) -> Optional[Type[Provider]]:
        if self == ProviderMapping.ollama:
            return OllamaProvider
        if self == ProviderMapping.openai:
            return OpenAIProvider

class OpenAIProvider(Provider):
    def __init__(self, **kwargs):
        proxy = kwargs.pop('proxy', None)
        self.no_content = kwargs.pop('no_content', False)
        self.client = OpenAI(
            http_client=httpx.Client(proxy=proxy) if proxy else None,
            base_url=kwargs.pop('base_url', kwargs.pop('host', None)) or None,
            **kwargs
        )

    @property
    def models(self):
        for m in self.client.models.list():
            yield m.id
    
    def chat(self, model, history=[], tools=[], tools_meta={}, model_index=None):
        qsend(str(tools))
        for chunk in self.client.chat.completions.create(model=model, messages=convert_history(history), tools=tools or None, stream=True):
            chunk: ChatCompletionChunk
            d = chunk.choices[0].delta
            for tool in d.tool_calls or []:
                if tool.function:
                    args = {}
                    if tool.function.arguments:
                        #qsend('toolArguments', str(tool.function.arguments))
                        try: args = json.loads(tool.function.arguments)
                        except: qsend('argumentsParseError', str(tool.function.arguments))
                    qsend(f'toolcall__{tool.function.name}', args)
            yield d.content or ('*No content*' if self.no_content else '')

class OllamaProvider(Provider):
    def __init__(self, **kwargs):
        self.no_content = kwargs.pop('no_content', False)
        kwargs.pop('api_key', None)
        self.client = Ollama(
            kwargs.pop('base_url', kwargs.pop('host', None)) or None,
            proxy=kwargs.pop('proxy', None) or None,
            **kwargs
        )

    @property
    def models(self):
        for m in self.client.list().models:
            if m.model is not None:
                yield m.model
    
    def chat(self, model, history=[], tools=[], tools_meta={}, model_index=None):
        h = convert_history(history)
        qsend(str(tools))
        qsend(str(h))
        try:
            for chunk in self.client.chat(model, h, tools=tools or None, stream=True):
                return_count = len([t for t in chunk.message.tool_calls or [] if tools_meta.get(t.function.name, default_tool_meta)['expect_return']])
                #expect_return = return_count > 0
                for tool in chunk.message.tool_calls or []:
                    #meta = tools_meta.get(tool.function.name, default_tool_meta)
                    yield None, tool.model_dump()
                    qsend(f'toolcall__{tool.function.name}', tool.function.arguments or {}, model_index, return_count)
                if chunk.message.content:
                    yield chunk.message.content or ('*No content*' if self.no_content else ''), None
                #if expect_return:
                #    pass
        except ollama._types.ResponseError as e:
            if 'does not support tools' in e.error:
                qsend("toolsError", model)
                yield '*Tools unsupported*', None
            else:
                raise e