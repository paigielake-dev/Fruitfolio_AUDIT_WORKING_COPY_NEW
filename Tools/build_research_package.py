#!/usr/bin/env python3
"""Import founder-supplied research without inventing source excerpts or references.
Requires python-docx and pdftotext. Reference blocks with ambiguous boundaries
remain unresolved and ineligible; all source paragraphs are retained in provenance.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from docx import Document


def sha(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b''): digest.update(block)
    return digest.hexdigest()


def identity(prefix, text):
    return prefix + hashlib.sha256(text.encode()).hexdigest()[:20]


def reference_records(text):
    # Preserve exact wording. Only clear reference boundaries are split.
    blocks = re.split(r'(?m)^\s*[•☆]\s+|(?m:^)(?=[A-Z][^\n]{1,160}\((?:19|20)\d{2}[a-z]?\)\.)', text)
    return [b.strip() for b in blocks if b.strip()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--corpus', required=True, type=Path)
    parser.add_argument('--guide', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--provenance', required=True, type=Path)
    args = parser.parse_args()
    corpus_hash, guide_hash = sha(args.corpus), sha(args.guide)
    version = 'founder-import-document-attribution-v2-' + corpus_hash[:12] + '-' + guide_hash[:12]
    document = Document(args.corpus)
    paragraphs = [{'index': i, 'style': p.style.name, 'text': p.text} for i, p in enumerate(document.paragraphs)]
    topics, topic = [], None
    for p in paragraphs:
        if p['style'] == 'Title':
            if topic: topics.append(topic)
            topic = {'heading': p['text'], 'paragraphs': [], 'start': p['index']}
        elif topic:
            topic['paragraphs'].append(p)
    if topic: topics.append(topic)
    notes, sources, source_chunks, issues, topic_index = [], {}, [], [], []
    corpus_id = 'founder_corpus_' + corpus_hash[:20]
    sources[corpus_id] = json.loads("{\"sourceID\":\"founder_corpus_13d89a17c6a65d0272b9\",\"title\":\"FruitsofLife.xo research corpus\",\"authors\":null,\"organization\":null,\"publicationDate\":null,\"publicationType\":\"Supplied educational research compilation; not an independently verified primary paper\",\"canonicalURL\":null,\"doi\":null,\"apa7Reference\":\"FruitsofLife.xo research corpus. (n.d.). Fruitfolio Research Library.\",\"verificationStatus\":\"founderCorpusAPA7\",\"retrievalEligibility\":true,\"sourceVersion\":\"13d89a17c6a65d0272b95ee4196853c109c4a760642e53e5a54d49d131d1aadd\",\"verifiedAt\":null,\"contentVersion\":\"founder-import-document-attribution-v2-13d89a17c6a6-f0edba71bf43\",\"provenance\":{\"file\":\"FruitsofLife_xo_Research_Corpus_APA7.docx\",\"titleFrom\":\"document cover\",\"author\":\"not identified; python-docx creator metadata is not authorship\",\"sourceScope\":\"actual supplied compilation, not each paper listed in its bibliography\"}}")
    sources[corpus_id]['contentVersion'] = version
    sources[corpus_id]['sourceID'] = corpus_id
    sources[corpus_id]['sourceVersion'] = corpus_hash
    sources[corpus_id]['provenance']['file'] = args.corpus.name
    for topic in topics:
        if topic['heading'] == 'FruitsofLife.xo Research Corpus': continue
        topic_id = identity('topic_', str(topic['start']) + ':' + topic['heading'])
        note_parts, bibliography = [], []
        mode = 'note'
        for p in topic['paragraphs']:
            text = p['text'].strip()
            if not text or text.startswith('Evidence-based compiled research notes on '): continue
            if p['style'] == 'Heading 1' and text.upper() in ['RESEARCH','SOURCES']:
                mode = 'reference' if text.upper() == 'SOURCES' else 'note'
                continue
            # A handful of topics embed a source heading in a normal paragraph.
            marker = re.search(r'(?im)^\s*sources\b[^\n]*\n', text)
            if mode == 'note' and marker:
                if text[:marker.start()].strip(): note_parts.append((p['index'], text[:marker.start()].strip()))
                bibliography.append(text[marker.end():])
                mode = 'reference'
            elif mode == 'reference': bibliography.append(text)
            else: note_parts.append((p['index'], text))
        refs = reference_records('\n'.join(bibliography))
        source_ids = []
        for raw in refs:
            reference_id = identity('ref_', raw)
            years = re.findall(r'\((?:19|20)\d{2}[a-z]?\)|\(n\.d\.\)', raw)
            # Never mark pasted prose or multi-reference fragments as verified APA.
            looks_formal = len(years) == 1 and len(raw) >= 45 and not re.search(r'(?m)^\s*[-•]\s', raw)
            looks_formal = looks_formal and raw.find(years[0]) < 450 if years else False
            status = 'unresolved'
            year = years[0][1:-1] if len(years) == 1 else None
            urls = re.findall(r'https?://[^\s<>]+', raw)
            url = urls[0].rstrip('.,);') if len(urls) == 1 else None
            source_ids.append(reference_id)
            sources.setdefault(reference_id, {
                'sourceID': reference_id, 'title': raw,
                'authors': None, 'organization': None, 'publicationDate': year,
                'publicationType': 'Reference transcribed from founder corpus; external source not independently checked',
                'canonicalURL': url, 'doi': None, 'apa7Reference': raw,
                'verificationStatus': status, 'retrievalEligibility': False,
                'bibliographyFormatAssessment': 'founderCorpusAPA7' if looks_formal else 'unresolved',
                'sourceVersion': corpus_hash, 'verifiedAt': None, 'contentVersion': version,
                'provenance': {'file': args.corpus.name, 'topic': topic['heading'], 'topicStartParagraph': topic['start'],
                               'association': 'topic bibliography, not independently verified claim entailment'}
            })
            if not looks_formal:
                issues.append({'topic': topic['heading'], 'referenceID': reference_id, 'reason': 'Ambiguous/non-APA reference block; preserved but not approved for citation display.'})
        for paragraph_index, text in note_parts:
            notes.append({'chunkID': f'{topic_id}_p{paragraph_index}', 'researchTopicID': topic_id,
                          'heading': topic['heading'], 'subheading': f'{args.corpus.name}, paragraph {paragraph_index + 1}',
                          'text': text, 'sourceIDs': [corpus_id], 'relatedSourceIDs': source_ids, 'semanticTags': [], 'domainTags': [],
                          'provenance': {'file': args.corpus.name, 'paragraphIndex': paragraph_index,
                                         'sourceAssociation': 'quoted from supplied compilation; relatedSourceIDs are bibliography only'}})
        topic_index.append({'id': topic_id, 'heading': topic['heading'], 'noteParagraphs': len(note_parts), 'referenceBlocks': len(refs)})
    # The uploaded authored guide is an approved local source in its own right.
    # No primary-paper excerpts are invented from bibliography entries.
    guide_id = 'founder_guide_' + guide_hash[:20]
    title = '@fruitsoflife.xo; pregnancy, postpartum, & women’s wellness guide (full)'
    sources[guide_id] = {
        'sourceID': guide_id, 'title': title, 'authors': 'FruitsofLife.xo', 'organization': None,
        'publicationDate': None, 'publicationType': 'Founder-authored educational guide',
        'canonicalURL': None, 'doi': None,
        'apa7Reference': 'FruitsofLife.xo. (n.d.). Pregnancy, postpartum, & women’s wellness guide [Unpublished educational guide].',
        'verificationStatus': 'founderCorpusAPA7', 'retrievalEligibility': True,
        'sourceVersion': guide_hash, 'verifiedAt': None, 'contentVersion': version,
        'provenance': {'file': args.guide.name, 'note': 'Authorship and title from cover/PDF metadata; publication date not inferred from file timestamps. This is a secondary educational source, not independent primary-paper verification.'}
    }
    guide_text = subprocess.check_output(['pdftotext','-layout',str(args.guide),'-'], text=True)
    pages = guide_text.split('\f')
    page_count = len(pages) - (1 if not pages[-1].strip() else 0)
    for index, page in enumerate(pages[:page_count], start=1):
        if not page.strip(): continue
        source_chunks.append({'sourceChunkID': f'{guide_id}_page_{index:04}', 'sourceID': guide_id,
                              'section': f'Page {index}', 'text': page.strip(),
                              'locationMetadata': f'{args.guide.name}#page={index}; sha256={guide_hash}',
                              'claimCategories': ['founder_authored_educational_guide'],
                              'provenance': {'file': args.guide.name, 'page': index}})
    package = {'schemaVersion': 1, 'contentVersion': version,
               'generatedFrom': args.corpus.name + ' + ' + args.guide.name,
               'generationNote': 'Deterministic verbatim import. Corpus references are topic-level associations, not proof of claim entailment or external verification. No primary-paper body text was downloaded. Only actual supplied guide pages populate sourceChunks. Note quotations cite the supplied compilation; all bibliography records remain unresolved and ineligible until original evidence is verified. Related bibliography associations are preserved separately. Clinical accuracy and APA normalization still require review.',
               'researchNoteChunks': notes, 'sources': list(sources.values()), 'sourceChunks': source_chunks}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(package, ensure_ascii=False, separators=(',', ':')))
    provenance = {'corpus': {'file': args.corpus.name, 'sha256': corpus_hash, 'paragraphs': paragraphs},
                  'guide': {'file': args.guide.name, 'sha256': guide_hash, 'pages': page_count},
                  'topicIndex': topic_index, 'reviewIssues': issues,
                  'counts': {'topics':len(topic_index),'noteChunks':len(notes),'sources':len(sources),
                             'eligibleSourceRecords':sum(s['retrievalEligibility'] for s in sources.values()),
                             'unresolvedReferenceBlocks':len(issues),'sourcePages':len(source_chunks)}}
    args.provenance.write_text(json.dumps(provenance, ensure_ascii=False, indent=2))
    print(json.dumps(provenance['counts'], indent=2))

if __name__ == '__main__': main()
