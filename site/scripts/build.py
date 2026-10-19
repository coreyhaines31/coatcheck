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

sections = {'guides': 'Guides', 'alternatives': 'Alternatives'}
organization = {'@type': 'Organization', '@id': site + '#maker', 'name': 'Coat Check', 'url': site}


def crumbs(page, url):
    trail = [('Coat Check', site)]
    parts = page['path'].split('/')
    if len(parts) > 2:
        trail.append((sections[parts[0]], f'{site}{parts[0]}/'))
    trail.append((page['crumb'], url))
    return trail


def breadcrumbs(page, url):
    if page['path'] == 'index.html':
        return ''
    *links, (current, _) = crumbs(page, url)
    items = ''.join(f'<li><a href="/{link.removeprefix(site)}">{escape(name)}</a></li>' for name, link in links)
    return f'<nav class="crumbs wrap" aria-label="Breadcrumb"><ol>{items}<li aria-current="page">{escape(current)}</li></ol></nav>'


def structured_data(page, url):
    if page['path'] == 'index.html':
        return json.dumps(app, ensure_ascii=False).replace('</', '<\\/')
    graph = [app, {'@type': 'BreadcrumbList', 'itemListElement': [
        {'@type': 'ListItem', 'position': i, 'name': name, 'item': link}
        for i, (name, link) in enumerate(crumbs(page, url), 1)]}]
    if len(page['path'].split('/')) == 3:
        graph += [organization, {
            '@type': 'TechArticle', 'headline': page['og_title'], 'description': page['description'],
            'url': url, 'mainEntityOfPage': url, 'image': site + 'og.png', 'dateModified': page['updated'],
            'inLanguage': 'en', 'author': {'@id': organization['@id']}, 'publisher': {'@id': organization['@id']},
        }]
    return json.dumps({'@context': 'https://schema.org', '@graph': graph}, ensure_ascii=False).replace('</', '<\\/')


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
    values['structured_data'] = structured_data(page, values['url'])
    content = (source / 'pages' / path).read_text().strip().replace('{{breadcrumbs}}', breadcrumbs(page, values['url']))
    values['content'] = fill(content)
    target = output / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(layout.substitute(values))
entries = sorted((site + page['path'].removesuffix('index.html'), page['updated']) for page in pages)
(output / 'sitemap.xml').write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + ''.join(f'  <url><loc>{escape(url)}</loc><lastmod>{updated}</lastmod></url>\n' for url, updated in entries)
    + '</urlset>\n')
print(f'Built {len(pages)} page(s) and the sitemap.')
