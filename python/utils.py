from datetime import datetime, timezone
from typing import Optional, Sequence, Tuple, Union, List, Dict
import urllib.parse
from enum import Enum, auto

class Role(Enum):
    user = 0
    assistant = 1
    system = 2

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
    if len(history) and isinstance(history[0], dict):
        return [{'role': Role(d['role']).name, 'content': d['content']} for d in history]

    return [{'role': Role(role).name, 'content': content} for role, content in history]

def convert_tool(name: str, description: str = '', parameters: Union[Dict[str, dict], None] = {}, required: Union[list, None] = []):
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
    }