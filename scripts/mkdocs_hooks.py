"""Keep repository-relative source links usable in the generated documentation."""

from pathlib import Path
import re
from urllib.parse import quote, urlsplit


def on_page_markdown(markdown, page, config, files):
    docs_root = Path(config['docs_dir']).resolve()
    repository_root = Path(config['config_file_path']).resolve().parent
    page_path = Path(page.file.abs_src_path)
    source_ref = config.get('extra', {}).get('source_ref', 'main')
    source_base = f"{config['repo_url'].rstrip('/')}/blob/{quote(source_ref, safe='/')}/"

    def source_link(match):
        target = urlsplit(match.group(2))
        if target.scheme or target.netloc or not target.path:
            return match.group(0)
        destination = (page_path.parent / target.path).resolve()
        if destination.is_relative_to(docs_root) or not destination.is_relative_to(repository_root):
            return match.group(0)
        if not destination.is_file():
            return match.group(0)
        url = source_base + quote(destination.relative_to(repository_root).as_posix(), safe='/')
        if target.fragment:
            url += '#' + target.fragment
        return f'[{match.group(1)}]({url})'

    return re.sub(r'\[([^\]]+)\]\(([^\s)]+)\)', source_link, markdown)
