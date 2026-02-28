# mynlpbash (v2)

**A collection of 115+ Bash scripts for NLP file processing, corpus analysis, classification data handling, parallel corpora, Indic language processing, terminal visualizations, and more.**

Built with pure Bash + standard Unix tools (`awk`, `sed`, `sort`, `cut`, `tr`, `paste`). No Python or external dependencies required. Cross-platform: macOS + Ubuntu.

---

## 🏗️ Project History

**mynlpbash** started as a personal toolkit of **31 scripts** built by [me](https://github.com/dipteshkanojia) for everyday NLP file wrangling — CSV/TSV converters, corpus tools, basic splits, and data cleanup. To take this from a random folder in my old data to a full blown library of first 68 scripts, it took e 3 prompts and barely 2 hours of reviewing. Rest in v2 was built on top of that; later, I also connected this library to IndicNLP (Anoop Kunchukuttan; cited below) for Indic language processing.

To supercharge the library, I used **Claude Opus** to grow it to **100 scripts**, introducing analytics, terminal visualizations, confusion matrices, inter-annotator agreement metrics, statistical profilers, NLP format converters, Unicode/Indic language processing, and a cross-platform compatibility layer.

### Authorship Convention

Every script carries a header declaring its origin:

```bash
# Author: Diptesh
# Status: Original — foundational script
```

```bash
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
```

---

## 📁 Categories

| Category | Count | Description |
|----------|:-----:|-------------|
| `file_processing/` | 16 | CSV/TSV/JSONL conversion, stats, filtering, joining, splitting |
| `corpus_analysis/` | 19 | MATTR, readability, TF-IDF, PMI, word frequency, n-grams, vocab |
| `parallel_corpora/` | 9 | Alignment checks, ratio analysis, synchronized operations |
| `classification/` | 10 | Class distribution, confusion matrix, F1 reports, error analysis |
| `nlp_specific/` | 7 | Sentiment stats, annotation agreement, label conversion, language detection |
| `data_quality/` | 6 | Duplicates, missing values, outliers, encoding checks |
| `format_conversion/` | 5 | CoNLL, BIO tags, FastText, LibSVM converters |
| `viz/` | 9 | Dispersion plots, histograms, heatmaps, sparklines, box plots |
| `unicode/` | 6 | Script detection, mixed-script analysis, Unicode normalization |
| `indic/` | 23 | Tokenization, transliteration, ML wrappers, code-mixing |
| `utils/` | 6 | File comparison, batch processing, report generation |
| **Total** | **117** | |

---

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/dipteshkanojia/mynlpbash.git
cd mynlpbash

# CSV statistics
bash file_processing/csv_stats.sh -i data.csv

# Word frequency with bar chart
bash corpus_analysis/word_freq.sh -i corpus.txt -n 20 --bar --lower

# Classification report (sklearn-style)
bash classification/classification_report.sh -g gold.txt -p pred.txt

# Color confusion matrix
bash viz/color_matrix.sh -g gold.txt -p pred.txt

# Detect code-mixing in Hindi-English text
bash indic/code_mixing_detect.sh -i mixed.txt --tag-words

# Transliterate Devanagari to IAST
bash indic/transliterate.sh -i hindi.txt

# Generate full dataset report
bash utils/generate_report.sh -i data.csv -c label -t text -o report.md
```

---

## 🔧 Cross-Platform Support

All scripts work on both **macOS** and **Ubuntu/Linux** via a compatibility layer in `lib/common.sh`:

| Feature | macOS | Linux |
|---------|-------|-------|
| `portable_sed_i` | `sed -i ''` | `sed -i` |
| `portable_shuf` | `gshuf` / awk fallback | `shuf` |
| `portable_filesize` | `stat -f%z` | `stat -c%s` |
| `portable_date` | `gdate` | `date` |
| `portable_md5` | `md5 -q` | `md5sum` |
| `portable_realpath` | `grealpath` / fallback | `realpath` |
| UTF-8 locale | Auto-enforced | Auto-enforced |

> **Note:** Scripts using `awk split()` on multibyte Indic characters (e.g., `akshar_count`, `indic_script_stats`) work best with `gawk` on macOS (`brew install gawk`). They work natively on Linux.

---

## 📋 Full Script Reference with Usage & Use Cases

### File Processing (`file_processing/`) — 17 scripts

Convert, filter, join, split, validate, and analyze CSV/TSV/JSONL files.

| Script | Description |
|--------|-------------|
| `csv_stats.sh` | Row/column counts, size, delimiter detection |
| `csv_to_tsv.sh` | Convert CSV → TSV |
| `tsv_to_csv.sh` | Convert TSV → CSV |
| `csv_to_jsonl.sh` | Convert CSV → JSON Lines |
| `jsonl_to_csv.sh` | JSON Lines → CSV |
| `csv_column_extract.sh` | Extract columns by name or index |
| `csv_filter.sh` | Filter rows by column value |
| `csv_sort.sh` | Sort by column (asc/desc) |
| `csv_merge.sh` | Vertically merge multiple CSVs |
| `csv_join.sh` | Join two CSVs on key column (inner/left/right/outer) |
| `csv_split.sh` | Split by chunk size or column value |
| `csv_deduplicate.sh` | Remove duplicate rows |
| `csv_sample.sh` | Random sampling |
| `csv_head_tail.sh` | Pretty-print first/last N rows |
| `csv_validate.sh` | Validate CSV structural integrity |
| `csv_transpose.sh` | Transpose rows ↔ columns |
| `hf_download_csv.sh` | Download HuggingFace datasets straight to CSV |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Data pipeline preprocessing**: Convert between CSV/TSV/JSONL for different tools
- **Train/test preparation**: Split, sample, shuffle, and deduplicate your datasets
- **Quick EDA**: `csv_stats` + `csv_head_tail` for instant dataset overview
- **Schema validation**: `csv_validate` before feeding into ML pipelines
- **Feature engineering**: `csv_join` to merge feature files, `csv_column_extract` to select columns
- **Data cleaning**: `csv_deduplicate` to remove duplicate rows before training
- **Dataset Streaming**: Use `hf_download_csv.sh` to grab HF datasets without parquet downloads
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Show file stats (rows, columns, delimiter, size)
bash file_processing/csv_stats.sh -i data.csv
#   File: data.csv | Rows: 20 | Columns: 3 | Delimiter: ,

# Convert CSV to TSV
bash file_processing/csv_to_tsv.sh -i data.csv -o data.tsv

# Convert TSV back to CSV
bash file_processing/tsv_to_csv.sh -i data.tsv -o data.csv

# Convert CSV to JSON Lines
bash file_processing/csv_to_jsonl.sh -i data.csv -o data.jsonl

# Convert JSON Lines to CSV
bash file_processing/jsonl_to_csv.sh -i data.jsonl -o data.csv

# Extract specific columns
bash file_processing/csv_column_extract.sh -i data.csv -c text,label
bash file_processing/csv_column_extract.sh -i data.csv -c 2      # by index

# Filter rows matching a value
bash file_processing/csv_filter.sh -i data.csv -c label -p "positive"
bash file_processing/csv_filter.sh -i data.csv -c label -p "positive|negative"

# Sort by column
bash file_processing/csv_sort.sh -i data.csv -c score --desc

# Merge multiple CSVs vertically
bash file_processing/csv_merge.sh -i train.csv test.csv -o combined.csv

# Join two CSVs on key column
bash file_processing/csv_join.sh -a users.csv -b scores.csv -k id --type inner
bash file_processing/csv_join.sh -a users.csv -b scores.csv -k id --type left

# Split into chunks of 1000 rows
bash file_processing/csv_split.sh -i data.csv -n 1000 -p chunk_

# Split by label column
bash file_processing/csv_split.sh -i data.csv -c label -p split_

# Remove duplicate rows
bash file_processing/csv_deduplicate.sh -i data.csv -o clean.csv

# Random sample of 500 rows
bash file_processing/csv_sample.sh -i data.csv -n 500 -o sample.csv

# Pretty-print first/last rows
bash file_processing/csv_head_tail.sh -i data.csv -n 10
bash file_processing/csv_head_tail.sh -i data.csv -n 5 --tail

# Validate CSV structure
bash file_processing/csv_validate.sh -i data.csv

# Transpose rows and columns
bash file_processing/csv_transpose.sh -i data.csv -o transposed.csv

# Download HuggingFace Dataset direct to CSV
bash file_processing/hf_download_csv.sh -d "dair-ai/emotion" -n 1000 -o emotion.csv
```
</details>

---

## 🇮🇳 IndicNLP Library Integration

**mynlpbash v2** integrates natively with the [indic_nlp_library](https://github.com/anoopkunchukuttan/indic_nlp_library) and [indic_nlp_resources](https://github.com/anoopkunchukuttan/indic_nlp_resources) to provide ML-backed functionality alongside the core pure-Bash scripts. 

### Setup

To enable the IndicNLP features, run the setup script once:
```bash
./setup_indicnlp.sh
```
This automatically clones the library and resources as Git submodules, installs the Python dependencies, and provides the environment variables (`lib/indicnlp_env.sh`).

### Wrapper Scripts (11)
These standalone scripts bridge the Python API to the `mynlpbash` CLI conventions:
- `indicnlp_tokenize.sh` / `indicnlp_detokenize.sh` / `indicnlp_sentence_split.sh`
- `indicnlp_normalize.sh` / `indicnlp_morph.sh` / `indicnlp_syllabify.sh`
- `indicnlp_transliterate.sh` / `indicnlp_romanize.sh` / `indicnlp_script_unify.sh`
- `indicnlp_langinfo.sh` (Check character parameters: *vowels, consonants, nuktas*)
- `indicnlp_phonetic_sim.sh` (Compute phonetic similarity across scripts)

### Delegation Flags
5 existing core Bash scripts have been enhanced with a `--use-indicnlp` flag, which automatically delegates the processing to the advanced Python ML models when specified:
- `indic_tokenize.sh`
- `indic_sentence_split.sh` 
- `devanagari_normalize.sh`
- `transliterate.sh` 
- `akshar_count.sh`

---

### Corpus Analysis (`corpus_analysis/`) — 15 scripts

Analyze, tokenize, normalize, and search text corpora.

| Script | Description |
|--------|-------------|
| `word_freq.sh` | Word frequency with top-N, min-freq, bar chart |
| `char_freq.sh` | Character frequency analysis |
| `ngram_extract.sh` | Extract n-grams (bigrams, trigrams, etc.) |
| `vocab_extract.sh` | Extract vocabulary (sorted unique words) |
| `corpus_stats.sh` | Tokens, types, TTR, hapax legomena |
| `lexical_diversity.sh` | MATTR, MSTTR, and standard TTR lexical diversity |
| `readability_scores.sh` | Flesch-Kincaid, Flesch Reading Ease, Gunning Fog |
| `tfidf_extract.sh` | Extract top keywords using Term Frequency-Inverse Document Frequency |
| `collocation_pmi.sh` | Extract significant bigrams using Pointwise Mutual Information (PMI) |
| `sentence_split.sh` | Split into one sentence per line |
| `tokenize.sh` | Word/character tokenization |
| `normalize_text.sh` | Lowercase, strip accents, normalize whitespace |
| `stopword_remove.sh` | Remove English stopwords |
| `clean_text.sh` | Remove HTML tags, URLs, emails |
| `corpus_search.sh` | KWIC concordance search |
| `line_length_stats.sh` | Length stats with percentiles and histogram |
| `encoding_detect.sh` | Detect and convert encoding |
| `shuffle_corpus.sh` | Shuffle lines randomly |
| `deduplicate_lines.sh` | Remove duplicate lines |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Corpus linguistics**: Word frequency, n-grams, TTR, hapax legomena analysis, MATTR lexical diversity
- **Information Retrieval**: TF-IDF keyword extraction, collocation PMI
- **Readability assessment**: Flesch-Kincaid and Gunning Fog approximations
- **Data preprocessing**: Tokenize, normalize, clean text before feeding to models
- **Vocabulary analysis**: Extract vocabulary, check coverage, find stopwords
- **Concordance studies**: KWIC search for keyword-in-context analysis
- **Text cleaning pipeline**: Remove HTML, URLs, emails → normalize → tokenize → remove stopwords
- **Deduplication**: Remove duplicate lines from web-crawled corpora
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Top 20 words with bar chart (lowercased)
bash corpus_analysis/word_freq.sh -i corpus.txt -n 20 --lower --bar
#        26 the    ██████████████████████████████
#         7 in     ████████

# Character frequency (top 10)
bash corpus_analysis/char_freq.sh -i corpus.txt -n 10

# Extract bigrams (top 15)
bash corpus_analysis/ngram_extract.sh -i corpus.txt -n 2 --top 15

# Extract trigrams
bash corpus_analysis/ngram_extract.sh -i corpus.txt -n 3 --top 10

# Extract vocabulary to file
bash corpus_analysis/vocab_extract.sh -i corpus.txt -o vocab.txt

# Full corpus statistics
bash corpus_analysis/corpus_stats.sh -i corpus.txt
#   Tokens: 230 | Types: 171 | TTR: 0.74 | Hapax: 151 (88.3%)

# Lexical Diversity (MATTR / MSTTR)
bash corpus_analysis/lexical_diversity.sh -i corpus.txt --window 50

# Readability Scores (Flesch-Kincaid, Gunning Fog)
bash corpus_analysis/readability_scores.sh -i corpus.txt

# Extract Keywords (TF-IDF)
bash corpus_analysis/tfidf_extract.sh -i corpus.txt -n 10 --lower

# Extract Collocations (PMI)
bash corpus_analysis/collocation_pmi.sh -i corpus.txt -n 10 --min-freq 2 --lower

# Split text into sentences
bash corpus_analysis/sentence_split.sh -i raw_text.txt -o sentences.txt

# Tokenize text
bash corpus_analysis/tokenize.sh -i corpus.txt -o tokens.txt

# Normalize: lowercase + collapse whitespace
bash corpus_analysis/normalize_text.sh -i corpus.txt --lower --collapse-ws

# Remove English stopwords
bash corpus_analysis/stopword_remove.sh -i corpus.txt -o no_stop.txt

# Clean HTML/URLs/emails
bash corpus_analysis/clean_text.sh -i raw.txt --html --urls --emails -o clean.txt

# KWIC concordance search
bash corpus_analysis/corpus_search.sh -i corpus.txt -p "language" -w 5

# Line length distribution
bash corpus_analysis/line_length_stats.sh -i corpus.txt --tokens --histogram

# Detect encoding
bash corpus_analysis/encoding_detect.sh -i file.txt

# Shuffle lines
bash corpus_analysis/shuffle_corpus.sh -i corpus.txt -o shuffled.txt

# Remove duplicate lines
bash corpus_analysis/deduplicate_lines.sh -i corpus.txt -o unique.txt
```
</details>

---

### Parallel Corpora (`parallel_corpora/`) — 9 scripts

Manage, validate, and manipulate aligned parallel text files.

| Script | Description |
|--------|-------------|
| `parallel_check.sh` | Verify alignment (line counts, empty lines, ratios) |
| `parallel_stats.sh` | Per-side and cross-side statistics |
| `length_ratio.sh` | Length ratio analysis and filtering |
| `parallel_split.sh` | Train/dev/test split preserving alignment |
| `parallel_shuffle.sh` | Shuffle maintaining alignment |
| `parallel_filter.sh` | Filter by length, ratio, or pattern |
| `parallel_dedup.sh` | Remove duplicate sentence pairs |
| `parallel_merge.sh` | Merge into tab-separated file |
| `parallel_extract.sh` | Extract side from merged file |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Machine translation**: Prepare and validate parallel training data
- **Quality control**: Check alignment, spot empty lines, detect bad length ratios
- **Data splitting**: Create aligned train/dev/test splits
- **Filtering**: Remove too-short/too-long pairs, filter by length ratio
- **Cross-lingual NLP**: Prepare bilingual dictionaries and glossaries
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Check alignment
bash parallel_corpora/parallel_check.sh -s source.en -t target.fr
#   Source lines: 15 | Target lines: 15 | ✓ Match

# Per-side statistics
bash parallel_corpora/parallel_stats.sh -s source.en -t target.fr

# Length ratio analysis (per pair)
bash parallel_corpora/length_ratio.sh -s source.en -t target.fr

# Split 80/10/10 preserving alignment
bash parallel_corpora/parallel_split.sh -s source.en -t target.fr -o data

# Shuffle both sides in sync
bash parallel_corpora/parallel_shuffle.sh -s source.en -t target.fr -o shuffled

# Filter: keep pairs with 5-50 tokens, ratio ≤ 2.0
bash parallel_corpora/parallel_filter.sh -s source.en -t target.fr --min 5 --max 50 --ratio 2.0

# Remove duplicate pairs
bash parallel_corpora/parallel_dedup.sh -s source.en -t target.fr -o dedup

# Merge into single tab-separated file
bash parallel_corpora/parallel_merge.sh -s source.en -t target.fr -o merged.tsv

# Extract source side from merged file
bash parallel_corpora/parallel_extract.sh -i merged.tsv -c 1 -o source.txt
```
</details>

---

### Classification (`classification/`) — 10 scripts

Evaluate, split, balance, and analyze classification datasets.

| Script | Description |
|--------|-------------|
| `class_distribution.sh` | Class counts, percentages, bar chart, imbalance ratio |
| `label_stats.sh` | Per-label text length and token statistics |
| `multilabel_stats.sh` | Multi-label cardinality, co-occurrence |
| `stratified_split.sh` | Stratified train/dev/test preserving class proportions |
| `cross_validate_split.sh` | k-fold cross-validation splits |
| `balance_classes.sh` | Undersample majority or oversample minority |
| `confusion_matrix.sh` | Confusion matrix from gold/predicted labels |
| `classification_report.sh` | Per-class precision, recall, F1 + macro/weighted |
| `prediction_compare.sh` | Compare two model predictions |
| `error_analysis.sh` | Extract misclassified samples grouped by confusion pair |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Model evaluation**: `classification_report` + `confusion_matrix` for sklearn-style metrics in Bash
- **Error debugging**: `error_analysis` to find systematic misclassification patterns
- **Dataset preparation**: Stratified splits preserving class ratios
- **Class imbalance**: Detect imbalance with `class_distribution`, fix with `balance_classes`
- **Model comparison**: Compare two model predictions with `prediction_compare`
- **Annotation quality**: Check label consistency with `multilabel_stats`
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Class distribution with bar chart
bash classification/class_distribution.sh -i data.csv -c label
#   negative   5  25.0%  ███████████████████
#   positive   4  20.0%  ███████████████

# Per-label text length stats
bash classification/label_stats.sh -i data.csv -c label -t text

# Multi-label analysis
bash classification/multilabel_stats.sh -i data.csv -c tags -s ","

# Stratified 80:10:10 split
bash classification/stratified_split.sh -i data.csv -c label -p 80:10:10 --shuffle -o split

# 5-fold cross-validation
bash classification/cross_validate_split.sh -i data.csv -k 5 --shuffle -o fold

# Balance classes
bash classification/balance_classes.sh -i data.csv -c label --method undersample -o balanced.csv
bash classification/balance_classes.sh -i data.csv -c label --method oversample -o balanced.csv

# Confusion matrix
bash classification/confusion_matrix.sh -g gold.txt -p predictions.txt
#   Gold\Pred      negative  positive  sarcasm
#   negative            5         0        0
#   positive            0         5        0
#   Accuracy: 80.0%

# Classification report (sklearn-style)
bash classification/classification_report.sh -g gold.txt -p predictions.txt
#   Label       Precision  Recall  F1-Score  Support
#   negative       0.7143  1.0000    0.8333        5
#   accuracy                         0.8000       20

# Compare two models
bash classification/prediction_compare.sh -a model1.txt -b model2.txt -g gold.txt

# Error analysis — find misclassification patterns
bash classification/error_analysis.sh -g gold.txt -p pred.txt
bash classification/error_analysis.sh -g gold.txt -p pred.txt -t texts.txt --top 5
#   sarcasm → negative     1 errors (25.0%)
#   neutral → positive     1 errors (25.0%)
```
</details>

---

### NLP-Specific (`nlp_specific/`) — 7 scripts

Specialized NLP tools for sentiment, annotations, labels, and language detection.

| Script | Description |
|--------|-------------|
| `label_convert.sh` | Remap labels (text ↔ numeric) |
| `sentiment_stats.sh` | Sentiment-specific analysis (punctuation, caps, length) |
| `annotation_agreement.sh` | Cohen's kappa inter-annotator agreement |
| `binary_to_multiclass.sh` | Convert multiclass → binary |
| `data_augment_shuffle.sh` | Word-level shuffle augmentation |
| `lang_detect.sh` | N-gram-based language detection |
| `subword_stats.sh` | Subword tokenizer fertility estimation |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Annotation projects**: Compute inter-annotator agreement (Cohen's kappa)
- **Sentiment analysis**: Analyze punctuation, caps, and length patterns per sentiment class
- **Label mapping**: Convert text labels to numeric for ML frameworks
- **Multiclass → binary**: Simplify tasks (e.g., positive vs rest)
- **Data augmentation**: Word shuffle for text classification augmentation
- **Multilingual**: Detect language per line (English, Hindi, French, German, Spanish, Bengali, Tamil, Telugu)
- **Tokenization research**: Estimate BPE/SentencePiece fertility on your corpus
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Map text labels to numeric
bash nlp_specific/label_convert.sh -i data.csv -c label --map 'positive=1,negative=0,neutral=2'

# Sentiment-specific stats
bash nlp_specific/sentiment_stats.sh -i data.csv -c label -t text

# Cohen's kappa between two annotators
bash nlp_specific/annotation_agreement.sh -a annotator1.txt -b annotator2.txt
#   Observed agreement: 0.8000 (80.0%)
#   Cohen's kappa:      0.7333
#   Interpretation:     Substantial agreement

# Convert to binary: positive vs rest
bash nlp_specific/binary_to_multiclass.sh -i data.csv -c label --to-binary --pos positive

# Augment data by word shuffling
bash nlp_specific/data_augment_shuffle.sh -i data.csv -c text -n 2 --keep-orig -o augmented.csv

# Language detection
bash nlp_specific/lang_detect.sh -i text.txt --per-line
#   English    This is an English sentence
#   Hindi      यह हिंदी वाक्य है

# Subword tokenizer fertility
bash nlp_specific/subword_stats.sh -i corpus.txt --vocab vocab.txt
```
</details>

---

### Data Quality (`data_quality/`) — 6 scripts

Find and fix data quality problems.

| Script | Description |
|--------|-------------|
| `find_empty_lines.sh` | Find and optionally remove empty lines |
| `find_duplicates.sh` | Find duplicate rows with occurrence counts |
| `missing_values.sh` | Per-column missing value report |
| `outlier_detect.sh` | Detect text length outliers (IQR method) |
| `data_profile.sh` | Comprehensive dataset profiling |
| `check_encoding.sh` | Check encoding, BOM, CRLF, null bytes |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Data auditing**: Profile entire dataset before model training
- **Quality assurance**: Find missing values, duplicates, encoding issues
- **Outlier detection**: Find unusually long/short texts
- **Encoding fixes**: Detect and convert encoding, strip BOM, fix line endings
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Report empty lines
bash data_quality/find_empty_lines.sh -i corpus.txt
bash data_quality/find_empty_lines.sh -i corpus.txt --remove -o clean.txt

# Find duplicate rows
bash data_quality/find_duplicates.sh -i data.csv --top 10
bash data_quality/find_duplicates.sh -i data.csv -c text # duplicates in specific column

# Missing value report
bash data_quality/missing_values.sh -i data.csv
#   Col  Name     Missing    %    Status
#   1    id       0          0.0% ✓
#   2    text     0          0.0% ✓
#   3    label    0          0.0% ✓

# Detect text length outliers
bash data_quality/outlier_detect.sh -i data.csv -c text --by tokens --factor 1.5

# Full dataset profile
bash data_quality/data_profile.sh -i data.csv

# Check encoding issues
bash data_quality/check_encoding.sh -i file.txt --fix -o fixed.txt
```
</details>

---

### Format Conversion (`format_conversion/`) — 5 scripts

Convert between NLP-specific formats.

| Script | Description |
|--------|-------------|
| `conll_to_csv.sh` | CoNLL → CSV with sentence IDs |
| `csv_to_conll.sh` | CSV → CoNLL format |
| `bio_tags_check.sh` | Validate BIO/IOB/BIOES tag sequences |
| `fasttext_format.sh` | Bidirectional FastText ↔ CSV converter |
| `libsvm_to_csv.sh` | LibSVM sparse → dense CSV |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **NER projects**: Convert between CoNLL and CSV for annotation tools
- **Sequence labeling**: Validate BIO tag consistency before training
- **FastText**: Convert datasets to/from FastText `__label__` format
- **LibSVM**: Convert sparse feature files to dense CSV for analysis
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# CoNLL to CSV
bash format_conversion/conll_to_csv.sh -i data.conll --columns "token,pos,ner" -o data.csv

# CSV to CoNLL
bash format_conversion/csv_to_conll.sh -i data.csv --sent-col sentence_id -o data.conll

# Validate BIO tag sequences
bash format_conversion/bio_tags_check.sh -i tagged.txt --format bio

# CSV to FastText
bash format_conversion/fasttext_format.sh --to-fasttext -i data.csv -c label -t text -o data.ft
#   __label__pos hello world
#   __label__neg bad thing

# FastText to CSV
bash format_conversion/fasttext_format.sh --from-fasttext -i data.ft -o data.csv

# LibSVM to CSV
bash format_conversion/libsvm_to_csv.sh -i features.libsvm -o features.csv
```
</details>

---

### Visualizations (`viz/`) — 8 scripts

Terminal-based data visualization with Unicode characters and ANSI colors.

| Script | Description |
|--------|-------------|
| `histogram.sh` | Horizontal/vertical histogram with auto-binning |
| `heatmap.sh` | Terminal heatmap using Unicode shading (`░▒▓█`) |
| `sparkline.sh` | Inline sparklines using `▁▂▃▄▅▆▇█` |
| `boxplot.sh` | Terminal box plot (min, Q1, median, Q3, max) |
| `bar_chart.sh` | Colored bar chart with labels |
| `scatter_plot.sh` | Terminal scatter plot on character grid |
| `color_matrix.sh` | Color-coded confusion matrix (green = correct, red = error) |
| `progress_dashboard.sh` | Live-updating progress bar with ETA |
| `dispersion_plot.sh` | Terminal-based lexical dispersion plot (NLTK style) |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Quick data exploration**: Visualize distributions without leaving the terminal
- **ML reports**: Color confusion matrix + histogram of token lengths
- **Pipeline monitoring**: Progress dashboard for batch processing
- **Presentations**: Terminal-based charts for SSH demos and README screenshots
- **EDA notebooks**: Sparklines for quick trend visualization
- **Quality checks**: Box plots to spot outlier distributions
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Histogram (horizontal) with 5 bins
awk '{print NF}' corpus.txt > /tmp/lengths.txt
bash viz/histogram.sh -i /tmp/lengths.txt --bins 5
#   [ 10.0 -  11.2]  11 ████████████████████████████████████████
#   [ 11.2 -  12.4]   7 █████████████████████████
#   [ 12.4 -  13.6]   1 ███

# Histogram (vertical)
bash viz/histogram.sh -i /tmp/lengths.txt --bins 8 --vertical

# Terminal heatmap from a matrix
bash viz/heatmap.sh -i matrix.csv

# Sparkline from numbers
bash viz/sparkline.sh -i /tmp/lengths.txt --label "Tokens:"
#   Tokens: █▂▃▄▁▃▂▃▁▂▁▂▃▁▃▂▂▂▃▃  (min: 10.0, max: 16.0, n: 20)

# Box plot
bash viz/boxplot.sh -i /tmp/lengths.txt --label "tokens"
#   tokens     ├───────│━━━━━━━│────────────┤
#              10                            16
#   Median: 11 | Q1: 11 | Q3: 12 | IQR: 1

# Bar chart (from label=value pairs)
echo -e "positive\t120\nnegative\t85\nneutral\t45" | bash viz/bar_chart.sh --title "Sentiment" --color green

# Bar chart from file
bash viz/bar_chart.sh -i label_counts.tsv --sort value --color blue

# Scatter plot
bash viz/scatter_plot.sh -i data.csv -x 1 -y 2 --width 60 --height 20

# Color confusion matrix (green=correct, red=errors)
bash viz/color_matrix.sh -g gold.txt -p pred.txt
#   negative  ✅5   ·    ·    ·
#   neutral   ❌1   ✅3  ❌1   ·
#   positive   ·    ·   ✅5   ·

# Lexical Dispersion plot (NLTK style)
bash viz/dispersion_plot.sh -i corpus.txt -w "language,text,data" --width 40
#   Word | 0                   |                  N
#        | ----------------------------------------
#   text |                         │ │    │         (3 hits)
#   data |           │                    │         (2 hits)

# Progress bar for batch processing
for i in $(seq 1 100); do echo $i; sleep 0.05; done | bash viz/progress_dashboard.sh --total 100 --label "Training"
#   Training [████████████████████████████░░░░░░░] 80% (80/100) ETA: 1s
```
</details>

---

### Unicode (`unicode/`) — 6 scripts

Unicode-aware text analysis, script detection, and normalization.

| Script | Description |
|--------|-------------|
| `unicode_stats.sh` | Character categories (letter, digit, punct) and script block breakdown |
| `detect_script.sh` | Detect dominant script per line (Devanagari, Latin, Bengali, Tamil, etc.) |
| `mixed_script_detect.sh` | Flag lines with multiple scripts (code-mixing detection) |
| `normalize_unicode.sh` | Unicode normalization (NFC/NFD/NFKC/NFKD) |
| `strip_diacritics.sh` | Remove combining diacritical marks |
| `char_class_filter.sh` | Filter/keep text by Unicode script or character class |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Multilingual NLP**: Detect script composition of a corpus
- **Code-mixing research**: Find and measure Hindi-English, Tamil-English mixed text
- **Data cleaning**: Strip diacritics, normalize Unicode forms, remove unwanted scripts
- **Preprocessing**: Filter only Devanagari text from mixed collections
- **Quality assurance**: Detect unexpected scripts in monolingual corpora
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Unicode character stats
bash unicode/unicode_stats.sh -i text.txt
#   Letters:    1267 (84.6%)
#   Digits:        0 (0.0%)
#   Script Blocks:
#     Latin:     1267 (84.6%)

# Detect dominant script per line
bash unicode/detect_script.sh -i text.txt --per-line
#   Devanagari    बिल्ली चटाई पर बैठी थी
#   Latin         The cat sat on the mat

# Detect code-mixed lines
bash unicode/mixed_script_detect.sh -i mixed.txt --threshold 2

# Normalize Unicode (NFC)
bash unicode/normalize_unicode.sh -i text.txt --form NFC --strip-zwj -o normalized.txt

# Strip diacritics
bash unicode/strip_diacritics.sh -i text.txt -o ascii.txt
#   café résumé → cafe resume

# Extract only Devanagari text
bash unicode/char_class_filter.sh -i mixed.txt --keep devanagari -o hindi_only.txt

# Remove Latin from mixed text
bash unicode/char_class_filter.sh -i mixed.txt --remove latin -o no_english.txt
```
</details>

---

### Indic Languages (`indic/`) — 12 scripts

Specialized tools for Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati, Kannada, Malayalam, and Indic NLP.

| Script | Description |
|--------|-------------|
| `indic_tokenize.sh` | Indic-aware tokenizer (purna viram, dandas, ZWJ) |
| `indic_sentence_split.sh` | Split on `।`, `॥`, `.!?` |
| `indic_char_freq.sh` | Character frequency by category (consonants, vowels, matras) |
| `indic_script_stats.sh` | Per-script breakdown with code-mixing ratio |
| `code_mixing_detect.sh` | Code-switching analysis with CMI |
| `transliterate.sh` | Devanagari → IAST romanization |
| `devanagari_normalize.sh` | Nukta, chandrabindu, ZWJ normalization |
| `indic_stopwords.sh` | Stopword removal (6 languages) |
| `indic_ngram.sh` | Indic-aware n-gram extraction |
| `akshar_count.sh` | Count orthographic syllables (akshars) |
| `parallel_indic_check.sh` | Indic-specific parallel corpus checks |
| `indic_vocab_coverage.sh` | Vocabulary coverage against frequency lists |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Indic NLP research**: Tokenize, split, normalize Hindi/Bengali/Tamil text
- **Code-mixing studies**: Detect and measure Hindi-English switching (CMI)
- **Transliteration**: Convert Devanagari to IAST romanization for analysis
- **Normalization**: Standardize nukta variants, chandrabindu, ZWJ/ZWNJ
- **Annotation tools**: Count akshars for text length analysis in Indic scripts
- **Translation QA**: Check for untranslated English in Indic targets
- **Stopword filtering**: Built-in lists for Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Indic-aware tokenization (separates purna viram)
bash indic/indic_tokenize.sh -i hindi.txt -o tokens.txt
#   बिल्ली चटाई पर बैठी थी ।

# Split on Indic sentence terminators
bash indic/indic_sentence_split.sh -i hindi.txt

# Transliterate Devanagari to IAST (romanization)
bash indic/transliterate.sh -i hindi.txt
#   billalī caṭāī para baiṭhī thī

# Devanagari normalization
bash indic/devanagari_normalize.sh -i hindi.txt --nukta --digits --strip-zwj
#   Nukta: क़→क  | Digits: ३→3 | ZWJ/ZWNJ removed

# Remove Hindi stopwords
bash indic/indic_stopwords.sh -i hindi.txt --lang hindi -o no_stop.txt
# Also: --lang bengali, tamil, telugu, marathi, gujarati

# Indic bigrams
bash indic/indic_ngram.sh -i hindi.txt -n 2 --top 10
#   10  है ।
#    2  के लिए
#    2  कृत्रिम बुद्धिमत्ता

# Character n-grams
bash indic/indic_ngram.sh -i hindi.txt -n 3 --char --top 10

# Character frequency by category (consonants/vowels/matras)
bash indic/indic_char_freq.sh -i hindi.txt --script devanagari
#   Consonant  45%  |  Matra  25%  |  Vowel  15%  |  Halant  8%

# Code-mixing detection with per-word tagging
bash indic/code_mixing_detect.sh -i mixed.txt --tag-words
#   CMI=0.35  [HI|मैंने] [HI|आज] [EN|new] [EN|laptop] [HI|खरीदा]

# Per-script statistics
bash indic/indic_script_stats.sh -i mixed.txt
#   Devanagari  55.3%  |  Latin  38.2%  |  Digits  2.1%

# Count akshars (syllables) in Devanagari text
bash indic/akshar_count.sh -i hindi.txt --per-line

# Check Indic parallel corpus for issues
bash indic/parallel_indic_check.sh -s source_en.txt -t target_hi.txt
#   Target mostly Latin: 2 (1.5%)  ← untranslated lines

# Vocabulary coverage against frequency list
bash indic/indic_vocab_coverage.sh -i corpus.txt --vocab hindi_freq.txt
#   Covered: 85.2%  |  OOV: 14.8%

# Custom stopwords
bash indic/indic_stopwords.sh -i hindi.txt --lang hindi --custom my_stops.txt
```
</details>

---

### Utilities (`utils/`) — 6 scripts

General-purpose helpers.

| Script | Description |
|--------|-------------|
| `file_compare.sh` | Compare two data files (size, lines, diff) |
| `batch_process.sh` | Apply any script to multiple files with progress |
| `generate_report.sh` | Generate Markdown summary report for a dataset |
| `regex_extract.sh` | Extract patterns (emails, URLs, hashtags, dates) |
| `text_diff.sh` | Word-level diff between two text files |
| `dataset_compare.sh` | Compare two datasets (vocab, labels, lengths) |

<details>
<summary><strong>💡 Use Cases</strong></summary>

- **Data pipeline orchestration**: `batch_process` to apply any script to 100+ files
- **Pattern mining**: Extract all emails/URLs/hashtags from text
- **Dataset versioning**: Compare train vs test datasets for data leakage
- **Report generation**: Auto-generate Markdown dataset summaries
- **QA/diff**: Word-level diff to compare model outputs
</details>

<details>
<summary><strong>📝 Sample Usage</strong></summary>

```bash
# Compare two files
bash utils/file_compare.sh -a file1.txt -b file2.txt
bash utils/file_compare.sh -a train.csv -b test.csv --summary

# Batch word frequency on all .txt files
bash utils/batch_process.sh --script corpus_analysis/word_freq.sh --args '-n 10 --lower' -i *.txt --output-dir results/

# Generate Markdown report
bash utils/generate_report.sh -i data.csv -c label -t text -o report.md

# Extract patterns
bash utils/regex_extract.sh -i text.txt --type email
bash utils/regex_extract.sh -i text.txt --type url
bash utils/regex_extract.sh -i text.txt --type hashtag
bash utils/regex_extract.sh -i text.txt --type custom --pattern '[A-Z]{3,}'

# Word-level diff
bash utils/text_diff.sh -a gold.txt -b pred.txt
#   L6  - neutral → + positive

# Compare two datasets side-by-side
bash utils/dataset_compare.sh -a train.csv -b test.csv -c label -t text
```
</details>

---

## 📂 Sample Data

The `sample_data/` directory contains test datasets:

| File | Contents |
|------|----------|
| `sentiment.csv` | Sentiment/sarcasm classification (20 rows, 3 cols: id, text, label) |
| `multiclass.tsv` | Multi-class TSV with sublabels |
| `corpus.txt` | Mixed English NLP corpus (20 sentences) |
| `parallel_en.txt` | English parallel corpus (15 pairs) |
| `parallel_fr.txt` | French parallel corpus (15 pairs) |
| `parallel_hi.txt` | Hindi parallel corpus (15 pairs) |
| `gold.txt` | Gold/reference labels (20 labels) |
| `pred.txt` | Predicted labels (20 labels) |
| `hindi_corpus.txt` | Hindi Devanagari corpus (15 sentences) |
| `mixed_script.txt` | Hindi-English code-mixed text (15 sentences) |

---

## 🔧 Design Principles

- **Pipeline-friendly**: Read stdin, write stdout — chain with `|`
- **Self-documenting**: Every script supports `--help`
- **Portable**: Standard Unix tools only, macOS + Linux
- **UTF-8 native**: All scripts enforce UTF-8 locale
- **Shared library**: `lib/common.sh` provides argument parsing, colored output, CSV detection, cross-platform wrappers

---

## 📝 Walkthrough — Verification Results

### File Processing

```
═══ File Statistics ═══
  File:                sentiment.csv
  Size:                1.3K (1318 bytes)
  Delimiter:           , (CSV)
  Rows:                20
  Columns:             3
```

### Word Frequency (with bar chart)

```
       26 the                  ██████████████████████████████
        7 in                   ████████
        6 of                   ██████
        6 and                  ██████
        4 to                   ████
```

### Corpus Statistics

```
═══ Corpus Statistics ═══
  Lines/sentences:          20
  Characters:               1,517
  Words:                    230
  Tokens:                   230
  Types (unique):           171
  Hapax legomena:           151 (88.30%)
  Type-token ratio:         0.7435
```

### Classification Report

```
Label           Precision    Recall  F1-Score   Support
─────── ───────── ────── ──────── ───────
negative           0.7143    1.0000    0.8333         5
neutral            0.7500    0.6000    0.6667         5
positive           0.8333    1.0000    0.9091         5
sarcasm            1.0000    0.6000    0.7500         5
─────── ───────── ────── ──────── ───────
accuracy                               0.8000        20
macro avg          0.8244    0.8000    0.7898        20
weighted avg       0.8244    0.8000    0.7898        20
```

### Confusion Matrix

```
═══ Confusion Matrix ═══
Gold\Pred      negative    neutral   positive    sarcasm
──────── ────────── ────────── ────────── ──────────
negative              5          0          0          0
neutral               1          3          1          0
positive              0          0          5          0
sarcasm               1          1          0          3

Accuracy: 16/20 = 0.8000 (80.0%)
```

### Color Confusion Matrix (`viz/color_matrix.sh`)

```
  Gold\Pred      negative    neutral   positive    sarcasm
               ────────── ────────── ────────── ──────────
  negative     🟩         5         ·         ·         ·
  neutral      🟥         1 🟩         3 🟥         1         ·
  positive             ·         · 🟩         5         ·
  sarcasm      🟥         1 🟥         1         · 🟩         3

  Legend: 🟩 correct  🟥 errors  (intensity = frequency)
```

### Histogram

```
═══ Histogram (5 bins) ═══
  [   10.0 -    11.2]    11 ████████████████████████████████████████
  [   11.2 -    12.4]     7 █████████████████████████
  [   12.4 -    13.6]     1 ███
  [   13.6 -    14.8]     0
  [   14.8 -    16.0]     1 ███
```

### Box Plot

```
═══ Box Plot ═══
  tokens     ├───────│━━━━━━━│────────────┤
             10                            16
  N:              20
  Q1 (25th):      11
  Median:         11
  Q3 (75th):      12
  IQR:            1
```

### Sparkline

```
Tokens: █▂▃▄▁▃▂▃▁▂▁▂▃▁▃▂▂▂▃▃  (min: 10.0, max: 16.0, n: 20)
```

### Parallel Corpus Check

```
  Source lines:             15
  Target lines:             15
  ✓  Line counts match: 15
  Mean length ratio:        0.87
  Suspicious pairs:         0 (0.0%)
```

### Annotation Agreement

```
═══ Inter-Annotator Agreement ═══
  Total items:              20
  Agreements:               16
  Disagreements:            4
  Observed agreement:       0.8000 (80.0%)
  Expected agreement:       0.2500 (25.0%)
  Cohen's kappa:            0.7333
  Interpretation:           Substantial agreement
```

### Error Analysis

```
═══ Error Analysis ═══
  Total samples:  20
  Errors:         4 (20.0%)
  Error pairs:    4

  sarcasm → negative     1 errors (25.0%)
  sarcasm → neutral      1 errors (25.0%)
  neutral → negative     1 errors (25.0%)
  neutral → positive     1 errors (25.0%)
```

### Text Diff (Word-Level)

```
═══ Text Diff ═══
  L6     - neutral  →  + positive
  L8     - sarcasm  →  + negative
  L13    - sarcasm  →  + neutral
  L19    - neutral  →  + negative

  Identical: 16 (80.0%) | Different: 4 (20.0%)
```

### Unicode Stats

```
═══ Unicode Statistics ═══
  Lines:                    20
  Total characters:         1497
  Character Categories:
    Letters:               1267  (84.6%)
    Whitespace:             210  (14.0%)
    Punctuation:             20  ( 1.3%)
  Script Blocks:
    Latin:                 1267  (84.6%)
```

### Indic Tokenization

```
Input:  बिल्ली चटाई पर बैठी थी और खिड़की से बाहर उड़ते पक्षियों को देख रही थी।
Output: बिल्ली चटाई पर बैठी थी और खिड़की से बाहर उड़ते पक्षियों को देख रही थी ।
```

### Indic Transliteration (Devanagari → IAST)

```
Input:  प्राकृतिक भाषा प्रसंस्करण भाषाविज्ञान और कृत्रिम बुद्धिमत्ता का एक उपक्षेत्र है।
Output: prākṛtika bhāṣā prasaṃskaraṇa bhāṣāvijñāna aura kṛtrima buddhimattā kā eka upakṣetra hai.
```

### Indic Stopword Removal

```
Input:  बिल्ली चटाई पर बैठी थी और खिड़की से बाहर उड़ते पक्षियों को देख रही थी।
Output: बिल्ली चटाई बैठी खिड़की बाहर उड़ते पक्षियों देख रही थी।
Removed: 44/146 stopwords (30.1%)
```

### Indic N-grams

```
═══ Indic 2-grams (top 5) ═══
      10  है ।
       2  के लिए
       2  कृत्रिम बुद्धिमत्ता
       2  जाती है
       1  होते हैं
```

### Regex Extraction

```
═══ Pattern Extraction (email) ═══
  L1     test@example.com
  Total matches: 1
```

### Strip Diacritics

```
Input:  café résumé naïve
Output: cafe resume naive
```

If you use IndicNLP Library from here, please cite:

```
@misc{kunchukuttan2020indicnlp,
author = "Anoop Kunchukuttan",
title = "{The IndicNLP Library}",
year = "2020",
howpublished={\url{https://github.com/anoopkunchukuttan/indic_nlp_library/blob/master/docs/indicnlp.pdf}}
}
```

---

## 📄 License

MIT License. See individual script headers for authorship.
