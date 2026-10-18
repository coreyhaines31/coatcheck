from html import escape
from pathlib import Path
from string import Template
import json
import shutil

root = Path(__file__).resolve().parent.parent
source = root / 'src'
output = root / 'dist'
layout = Template((source / 'layouts/base.html').read_text())
release = '0.1.1'
download_url = f'https://github.com/coreyhaines31/coatcheck/releases/download/v{release}/CoatCheck-{release}-arm64.dmg'
partials = {name: (source / f'layouts/{name}.html').read_text().strip() for name in ('header', 'footer', 'get-coatcheck')}


def fill(text):
    text = text.replace('{{get_coatcheck}}', partials['get-coatcheck'])
    return text.replace('{{download_url}}', download_url).replace('{{release}}', release)


shared = {name: fill(partials[name]) for name in ('header', 'footer')}
pages = json.loads((source / 'pages.json').read_text())
site = 'https://coatcheckformac.com/'
app = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    'name': 'Coat Check',
    'description': 'A free, open-source macOS menu bar manager that lists every menu bar icon, including the ones the notch hides, and opens their menus.',
    'url': site,
    'applicationCategory': 'UtilitiesApplication',
    'operatingSystem': 'macOS 14 or later (Apple silicon)',
    'license': 'https://opensource.org/licenses/MIT',
    'downloadUrl': 'https://github.com/coreyhaines31/coatcheck/releases/latest',
    'image': site + 'og.png',
    'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'},
}

expected = {Path(page['path']) for page in pages} | {Path('sitemap.xml')}
assets = {path.relative_to(source / 'assets') for path in (source / 'assets').rglob('*') if path.is_file()}
if output.exists():
    for file in output.rglob('*'):
        if file.is_file() and file.relative_to(output) not in expected | assets:
            file.unlink()
for asset in assets:
    target = output / asset
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / 'assets' / asset, target)
for page in pages:
    path = page['path']
    values = {key: escape(page[key], quote=True) for key in ('title', 'description', 'og_title', 'og_description', 'body_class')}
    values.update(shared)
    values['url'] = site + path.removesuffix('index.html')
    values['structured_data'] = json.dumps(app, ensure_ascii=False).replace('</', '<\\/')
    values['content'] = fill((source / 'pages' / path).read_text().strip())
    target = output / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(layout.substitute(values))
entries = sorted((site + page['path'].removesuffix('index.html'), page['updated']) for page in pages)
(output / 'sitemap.xml').write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + ''.join(f'  <url><loc>{escape(url)}</loc><lastmod>{updated}</lastmod></url>\n' for url, updated in entries)
    + '</urlset>\n')
print(f'Built {len(pages)} page(s) and the sitemap.')
