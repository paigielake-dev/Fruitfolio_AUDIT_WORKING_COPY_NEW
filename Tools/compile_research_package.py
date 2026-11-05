#!/usr/bin/env python3
"""Compile existing founder DOCX notes losslessly; never invent claims/citations.

Only topics with an unambiguous explicit reference section may be retrieved.
Other original text is preserved as quarantined notes, not model evidence.
Citation metadata is not full-source scientific text: sourceChunks stays empty.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
YEAR = re.compile(r'\((?:\d{4}[a-z]?(?:,[^)]*)?|n\.d\.)\)')
MAXIMUM_CHUNK_CHARACTERS = 1600


def digest(data):
    return hashlib.sha256(data).hexdigest()


def paragraphs(path):
    with zipfile.ZipFile(path) as archive:
        document = ET.fromstring(archive.read('word/document.xml'))
    result = []
    for ordinal, paragraph in enumerate(document.iter(W + 'p')):
        fragments = []
        for node in paragraph.iter():
            if node.tag == W + 't': fragments.append(node.text or '')
            elif node.tag == W + 'tab': fragments.append('\t')
            elif node.tag in [W + 'br', W + 'cr']: fragments.append('\n')
        text = ''.join(fragments)
        if not text.strip(): continue
        style = paragraph.find(W + 'pPr/' + W + 'pStyle')
        result.append(dict(ordinal=ordinal, style=style.get(W + 'val') if style is not None else 'Normal', text=text))
    return result


def split_exact(text):
    offset = 0
    while offset < len(text):
        end = min(len(text), offset + MAXIMUM_CHUNK_CHARACTERS)
        if end < len(text):
            boundary = text.rfind(' ', offset + MAXIMUM_CHUNK_CHARACTERS // 2, end)
            if boundary > offset: end = boundary
        yield text[offset:end]
        offset = end


def reference(text, version):
    # Explicit APA-style source-list entry, not a citation guessed from prose.
    years = list(YEAR.finditer(text))
    if len(years) != 1 or years[0].start() < 2:
        return None
    identifier = 'source_' + digest(text.encode())[:24]
    address = None
    urls = re.findall(r'https?://[^\s<>]+', text)
    if len(urls) == 1 and not urls[0].endswith(('.', ',', ';', ')', ']')):
        try:
            components = urllib.parse.urlsplit(urls[0])
            if components.hostname and not components.username and not components.password:
                address = urls[0]
        except ValueError:
            pass  # Keep exact citation text; never guess a malformed address.
    doi = None
    if address:
        components = urllib.parse.urlsplit(address)
        if components.hostname in ['doi.org', 'dx.doi.org'] and not components.query and not components.fragment:
            doi = urllib.parse.unquote(components.path.lstrip('/'))
    return dict(sourceID=identifier, title=text, authors=None, organization=None,
                publicationDate=years[0].group()[1:-1], publicationType=None, canonicalURL=address,
                doi=doi, apa7Reference=text, verificationStatus='founderCorpusAPA7',
                retrievalEligibility='lifebridge' not in text.lower(), sourceVersion=version, verifiedAt=None, contentVersion=version)


def compile_package(corpus, voice_pdf=None):
    corpus_hash = digest(corpus.read_bytes())
    compiler_hash = digest(Path(__file__).read_bytes())
    version = 'founder-corpus-' + digest((corpus_hash + compiler_hash).encode())[:20]
    groups = []
    for paragraph in paragraphs(corpus):
        if paragraph['style'] == 'Title':
            groups.append(dict(title=paragraph['text'], start=paragraph['ordinal'], rows=[]))
        elif groups:
            groups[-1]['rows'].append(paragraph)
    notes, sources, provenance, quarantine, original_paragraphs = [], {}, [], [], {}
    for group in groups:
        if group['title'].strip() == 'FruitsofLife.xo Research Corpus': continue
        rows = group['rows']
        source_heading = next((i for i, row in enumerate(rows)
                               if row['text'].strip().upper() in ['SOURCES', 'REFERENCES', 'BIBLIOGRAPHY']), None)
        body = rows if source_heading is None else rows[:source_heading]
        reference_rows = [] if source_heading is None else rows[source_heading + 1:]
        parsed = [reference(row['text'], version) for row in reference_rows]
        reasons = []
        if not reference_rows: reasons.append('missing explicit nonempty reference section')
        elif any(item is None for item in parsed): reasons.append('ambiguous or unrecognized reference paragraph')
        combined = group['title'] + '\n' + '\n'.join(row['text'] for row in rows)
        if 'lifebridge' in combined.lower():
            reasons.append('LifeBridge requires reviewed snapshots from BOTH founder-specified sources')
        eligible = not reasons
        topic_id = 'topic_' + digest((str(group['start']) + '\n' + group['title']).encode())[:24]
        source_ids = []
        for item in parsed:
            if item is not None:
                sources[item['sourceID']] = item
                source_ids.append(item['sourceID'])
        if reasons:
            quarantine.append(dict(topicID=topic_id, title=group['title'], paragraph=group['start'], reasons=reasons))
        for row in body:
            text = row['text']
            if row['style'] == 'Heading1' and text.strip().upper() == 'RESEARCH': continue
            if text.startswith('Evidence-based compiled research notes on '): continue
            paragraph_id = 'docx_p_' + str(row['ordinal'])
            original_paragraphs[paragraph_id] = text
            for part, piece in enumerate(split_exact(text)):
                chunk_id = 'note_' + digest((topic_id + ':' + str(row['ordinal']) + ':' + str(part) + ':' + piece).encode())[:24]
                notes.append(dict(chunkID=chunk_id, researchTopicID=topic_id, heading=group['title'],
                                  subheading=None, text=piece, sourceIDs=source_ids, semanticTags=[], domainTags=[],
                                  retrievalEligibility=eligible, sourceParagraphID=paragraph_id))
                provenance.append(dict(chunkID=chunk_id, paragraph=row['ordinal'], part=part,
                                       text_sha256=digest(piece.encode()), retrievalEligibility=eligible))
    assets = [dict(path=str(corpus.relative_to(ROOT)) if corpus.is_relative_to(ROOT) else corpus.name,
                   sha256=corpus_hash, bytes=corpus.stat().st_size, role='approved founder research notes')]
    if voice_pdf:
        assets.append(dict(path=str(voice_pdf.relative_to(ROOT)) if voice_pdf.is_relative_to(ROOT) else voice_pdf.name,
                           sha256=digest(voice_pdf.read_bytes()), bytes=voice_pdf.stat().st_size,
                           role='preserved founder voice reference; not automatically compiled as scientific evidence'))
    package = dict(schemaVersion=1, contentVersion=version, generatedFrom=corpus.name,
                   generationNote='Exact DOCX paragraph slices. APA7 metadata is founder-corpus attribution, not independent source verification. Quarantined notes cannot be retrieved. No downloaded full-source text is fabricated from references.',
                   researchNoteChunks=notes, sources=list(sources.values()), sourceChunks=[], sourceParagraphs=original_paragraphs)
    report = dict(schemaVersion=1, compiler_sha256=compiler_hash, sourceAssets=assets, contentVersion=version,
                  topics=len(groups) - 1, noteChunks=len(notes), eligibleNoteChunks=sum(n['retrievalEligibility'] for n in notes),
                  sourceRecords=len(sources), eligibleSourceRecords=sum(source['retrievalEligibility'] for source in sources.values()), fullSourceChunks=0, quarantinedTopics=quarantine, provenance=provenance,
                  acceptance='Compilation and byte provenance only. Clinical correctness, citation validity, recall, integrated generation and Apple runtime remain separate verification requirements.')
    return package, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    assets = ROOT / 'Fruitfolio/Assets.xcassets'
    corpus = next(assets.rglob('FruitsofLife_xo_Research_Corpus_APA7.docx'))
    voice = next(assets.rglob('FruitsofLife.xo_Pregnancy_Postpartum_Wellness_Guide.pdf'))
    package, report = compile_package(corpus, voice)
    outputs = [(ROOT / 'Fruitfolio/FruitfolioResearchPackage.json', package),
               (ROOT / 'development_workflow/RESEARCH_PACKAGE_REPORT.json', report)]
    for path, value in outputs:
        encoded = json.dumps(value, ensure_ascii=False, indent=2) + '\n'
        if args.check:
            assert path.read_text() == encoded, f'Stale package/provenance: {path}'
        else:
            temporary = path.with_suffix(path.suffix + '.tmp')
            temporary.write_text(encoded)
            temporary.replace(path)
    print(json.dumps({key: report[key] for key in ['topics', 'noteChunks', 'eligibleNoteChunks', 'sourceRecords', 'fullSourceChunks']}))
    print(f"Quarantined topics: {len(report['quarantinedTopics'])}; original assets unchanged")


if __name__ == '__main__':
    main()
