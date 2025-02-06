from datetime import datetime, timezone
import json
from typing import Optional, Sequence, Tuple, Union, List, Dict
import urllib.parse
from enum import Enum, auto

class Role(Enum):
    user = 0
    assistant = 1
    system = 2
    tool = 3

def qml_date(date: datetime):
    """Convert to UTC Unix timestamp using milliseconds"""
    return date.replace(tzinfo=timezone.utc).timestamp()*1000

def convert_proxy(proxy) -> Optional[str]:
    if not proxy:
        return

    p = urllib.parse.urlparse(proxy, 'http') # https://stackoverflow.com/a/21659195
    netloc = p.netloc or p.path
    path = p.path if p.netloc else ''
    p = urllib.parse.ParseResult('http', netloc, path, *p[3:])

    return p.geturl()

def convert_history(history: Sequence[Union[Tuple[Union[int, Role], str], dict]]) -> List[Dict[str, str]]:
    res = []
    if len(history) and isinstance(history[0], dict):
        for d in history:
            res.append({'role': Role(d['role']).name, 'content': d['content']})
            if d.get('toolCalls', None):
                tool_calls = json.loads(d['toolCalls'])
                if tool_calls:
                    res[-1]['tool_calls'] = tool_calls
    else:
        for e in history:
            role, content = history[:2]
            tool_calls = history[2] if len(history) > 2 else None
            res.append({'role': Role(role).name, 'content': content})
            if tool_calls:
                tool_calls = json.loads(tool_calls)
                if tool_calls:
                    res[-1]['tool_calls'] = tool_calls

    return res

def convert_tool(name: str, description: str = '', parameters: Union[Dict[str, dict], None] = {}, required: Union[list, None] = [], expect_return: bool = False):
    parameters, required = parameters or {}, required or None
    return {
        'type': 'function',
        'function': {
            'name': name,
            'description': description,
            # 'parameters': {
            #     'type': 'object',
            #     'required': None,
            #     'properties': {},
            # }
            'parameters': {
                'type': 'object',
                'required': required,
                'properties': {
                    param: {
                        'type': props.get('type', 'string'),
                        'description': props.get('description', ''),
                    } for param, props in parameters.items()
                },
            }
        }
    }, {'expect_return': expect_return}

default_tool_meta = {'expect_return': False}