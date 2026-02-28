# mynlpbash

**A collection of 68 Bash scripts for NLP file processing, corpus analysis, classification data handling, and more.**

Built with pure Bash + standard Unix tools (`awk`, `sed`, `sort`, `cut`, `tr`, `paste`). No Python or external dependencies required. Taking this library from a random folder in my old data to THIS full fledged repo needed a total of 3 prompts with Claude Opus. :)

---

## 🏗️ Project History

**mynlpbash** started as a personal toolkit of **31 scripts** built by [me](https://github.com/dipteshkanojia) for everyday NLP file wrangling — CSV/TSV converters, corpus tools, basic splits, and data cleanup.

To supercharge the library, I used **Claude Opus** to introduce **37 extras, organization and visualizations**, bringing in analytics, terminal visualizations, confusion matrices, inter-annotator agreement metrics, statistical profilers, and NLP format converters. Some original scripts were also enhanced with AI-powered features like bar chart rendering, ratio analysis, and stratification logic.

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

The shared library `lib/common.sh` splits its functions into **Core Utilities (Diptesh)** and **AI-Enhanced Utilities (Claude Opus)**.

---

## 📁 Categories

| Category | Total | Original | AI-Enhanced (Claude Opus) |
|----------|:-----:|:------------------:|:-------------------------:|
| `file_processing/` | 16 | 11 | 5 |
| `corpus_analysis/` | 15 | 8 | 7 |
| `parallel_corpora/` | 9 | 5 | 4 |
| `classification/` | 9 | 3 | 6 |
| `nlp_specific/` | 5 | 1 | 4 |
| `data_quality/` | 6 | 2 | 4 |
| `format_conversion/` | 5 | 0 | 5 |
| `utils/` | 3 | 1 | 2 |
| **Total** | **68** | **31** | **37** |

---

## 🚀 Quick Start

```bash
# CSV statistics
bash file_processing/csv_stats.sh -i data.csv

# Word frequency with bar chart
bash corpus_analysis/word_freq.sh -i corpus.txt -n 20 --bar --lower

# Check parallel corpus alignment
bash parallel_corpora/parallel_check.sh -s source.en -t target.fr

# Classification report (sklearn-style)
bash classification/classification_report.sh -g gold.txt -p pred.txt

# Generate full Markdown dataset report
bash utils/generate_report.sh -i data.csv -c label -t text -o report.md
```

---

## 📋 Full Script Reference

### File Processing (`file_processing/`)

| Script | Description |
|--------|-------------|
| `csv_to_tsv.sh` | Convert CSV → TSV |
| `tsv_to_csv.sh` | Convert TSV → CSV |
| `csv_to_jsonl.sh` | Convert CSV → JSON Lines |
| `jsonl_to_csv.sh` | JSON Lines → CSV with pure-awk parsing |
| `csv_stats.sh` | Row/column counts, column details |
| `csv_column_extract.sh` | Extract columns by name or index |
| `csv_filter.sh` | Filter rows by regex or comparison |
| `csv_sort.sh` | Sort by column (asc/desc) |
| `csv_merge.sh` | Vertically merge multiple CSVs |
| `csv_join.sh` | Join on key column (inner/left/right/outer) |
| `csv_split.sh` | Split by chunk size or column value |
| `csv_deduplicate.sh` | Remove duplicate rows |
| `csv_sample.sh` | Random sampling |
| `csv_head_tail.sh` | Pretty-print first/last N rows |
| `csv_validate.sh` | Validate CSV structural integrity |
| `csv_transpose.sh` | Transpose rows ↔ columns |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Convert CSV to TSV
bash file_processing/csv_to_tsv.sh -i data.csv -o data.tsv

# Convert TSV back to CSV
bash file_processing/tsv_to_csv.sh -i data.tsv -o data.csv

# Convert CSV to JSON Lines
bash file_processing/csv_to_jsonl.sh -i data.csv -o data.jsonl

# Convert JSON Lines to CSV
bash file_processing/jsonl_to_csv.sh -i data.jsonl -o data.csv

# Show file statistics
bash file_processing/csv_stats.sh -i data.csv

# Extract text and label columns
bash file_processing/csv_column_extract.sh -i data.csv -c text,label

# Filter rows where label matches "positive"
bash file_processing/csv_filter.sh -i data.csv -c label --pattern "positive"

# Sort by column
bash file_processing/csv_sort.sh -i data.csv -c label

# Merge two CSVs vertically
bash file_processing/csv_merge.sh -i file1.csv file2.csv -o combined.csv

# Join two CSVs on a key column
bash file_processing/csv_join.sh -a file1.csv -b file2.csv -k id --type inner

# Split into chunks of 1000 rows
bash file_processing/csv_split.sh -i data.csv -n 1000 --prefix chunk

# Remove duplicate rows
bash file_processing/csv_deduplicate.sh -i data.csv -o clean.csv

# Random sample of 500 rows
bash file_processing/csv_sample.sh -i data.csv -n 500 -o sample.csv

# Pretty-print first 10 rows
bash file_processing/csv_head_tail.sh -i data.csv -n 10

# Validate CSV structure
bash file_processing/csv_validate.sh -i data.csv

# Transpose rows and columns
bash file_processing/csv_transpose.sh -i data.csv -o transposed.csv
```
</details>

---

### Corpus Analysis (`corpus_analysis/`)

| Script | Description |
|--------|-------------|
| `word_freq.sh` | Word frequency with top-N, min-freq, bar chart |
| `char_freq.sh` | Character frequency analysis |
| `ngram_extract.sh` | Extract n-grams (bigrams, trigrams, etc.) |
| `vocab_extract.sh` | Extract vocabulary (sorted unique words) |
| `corpus_stats.sh` | Tokens, types, TTR, hapax legomena |
| `sentence_split.sh` | Split into one sentence per line |
| `tokenize.sh` | Word/character tokenization |
| `normalize_text.sh` | Lowercase, strip accents, normalize whitespace |
| `stopword_remove.sh` | Remove stopwords |
| `clean_text.sh` | Remove HTML tags, URLs, emails |
| `corpus_search.sh` | KWIC concordance search |
| `line_length_stats.sh` | Length stats with percentiles and histogram |
| `encoding_detect.sh` | Detect and convert encoding |
| `shuffle_corpus.sh` | Shuffle lines randomly |
| `deduplicate_lines.sh` | Remove duplicate lines |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Top 20 words, lowercased, with bar chart
bash corpus_analysis/word_freq.sh -i corpus.txt -n 20 --lower --bar

# Character frequency (top 10)
bash corpus_analysis/char_freq.sh -i corpus.txt -n 10

# Extract bigrams (top 15)
bash corpus_analysis/ngram_extract.sh -i corpus.txt -n 2 --top 15

# Extract vocabulary
bash corpus_analysis/vocab_extract.sh -i corpus.txt -o vocab.txt

# Full corpus statistics (TTR, hapax, etc.)
bash corpus_analysis/corpus_stats.sh -i corpus.txt

# Split text into one sentence per line
bash corpus_analysis/sentence_split.sh -i raw_text.txt -o sentences.txt

# Tokenize text (word-level)
bash corpus_analysis/tokenize.sh -i corpus.txt -o tokens.txt

# Normalize: lowercase + collapse whitespace
bash corpus_analysis/normalize_text.sh -i corpus.txt --lower --collapse-ws

# Remove English stopwords
bash corpus_analysis/stopword_remove.sh -i corpus.txt -o no_stop.txt

# Clean HTML/URLs/emails
bash corpus_analysis/clean_text.sh -i raw.txt --html --urls --emails -o clean.txt

# Search for keyword in context (KWIC)
bash corpus_analysis/corpus_search.sh -i corpus.txt --pattern "machine learning" -w 5

# Line length distribution (by tokens)
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

### Parallel Corpora (`parallel_corpora/`)

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
<summary><strong>Sample Usage</strong></summary>

```bash
# Check alignment
bash parallel_corpora/parallel_check.sh -s source.en -t target.fr

# Per-side statistics
bash parallel_corpora/parallel_stats.sh -s source.en -t target.fr

# Analyze length ratios
bash parallel_corpora/length_ratio.sh -s source.en -t target.fr

# Split 80/10/10 preserving alignment
bash parallel_corpora/parallel_split.sh -s source.en -t target.fr -o data

# Shuffle both sides in sync
bash parallel_corpora/parallel_shuffle.sh -s source.en -t target.fr -o shuffled

# Filter: keep pairs with 5-50 tokens, ratio 0.5-2.0
bash parallel_corpora/parallel_filter.sh -s source.en -t target.fr --min 5 --max 50 --ratio 2.0

# Remove duplicate pairs
bash parallel_corpora/parallel_dedup.sh -s source.en -t target.fr -o dedup

# Merge into single tab-separated file
bash parallel_corpora/parallel_merge.sh -s source.en -t target.fr -o merged.tsv

# Extract source side from merged file
bash parallel_corpora/parallel_extract.sh -i merged.tsv -c 1 -o source_extracted.txt
```
</details>

---

### Classification (`classification/`)

| Script | Description |
|--------|-------------|
| `class_distribution.sh` | Class counts, percentages, bar chart, imbalance ratio |
| `label_stats.sh` | Per-label text length and token statistics |
| `multilabel_stats.sh` | Multi-label cardinality, co-occurrence |
| `stratified_split.sh` | Stratified train/dev/test preserving class proportions |
| `cross_validate_split.sh` | k-fold cross-validation splits |
| `balance_classes.sh` | Undersample majority or oversample minority |
| `confusion_matrix.sh` | Confusion matrix from gold/predicted labels |
| `classification_report.sh` | Per-class precision, recall, F1 + macro/weighted averages |
| `prediction_compare.sh` | Compare two prediction files |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Class distribution with bar chart
bash classification/class_distribution.sh -i data.csv -c label

# Per-label text length stats
bash classification/label_stats.sh -i data.csv -c label -t text

# Multi-label cooccurrence
bash classification/multilabel_stats.sh -i data.csv -c tags -s ","

# Stratified 80:10:10 split
bash classification/stratified_split.sh -i data.csv -c label -p 80:10:10 --shuffle -o split

# 5-fold cross-validation
bash classification/cross_validate_split.sh -i data.csv -k 5 --shuffle -o fold

# Undersample to balance classes
bash classification/balance_classes.sh -i data.csv -c label --method undersample -o balanced.csv

# Oversample minority classes
bash classification/balance_classes.sh -i data.csv -c label --method oversample -o balanced.csv

# Confusion matrix
bash classification/confusion_matrix.sh -g gold.txt -p predictions.txt

# Full classification report (sklearn-style)
bash classification/classification_report.sh -g gold.txt -p predictions.txt

# Compare two model predictions
bash classification/prediction_compare.sh -a model1_pred.txt -b model2_pred.txt -g gold.txt
```
</details>

---

### NLP-Specific (`nlp_specific/`)

| Script | Description |
|--------|-------------|
| `label_convert.sh` | Remap labels (text↔numeric) |
| `sentiment_stats.sh` | Sentiment-specific analysis (punctuation, caps) |
| `annotation_agreement.sh` | Cohen's kappa inter-annotator agreement |
| `binary_to_multiclass.sh` | Convert multiclass → binary by specifying positive class(es) |
| `data_augment_shuffle.sh` | Word-level shuffle augmentation |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Map text labels to numeric
bash nlp_specific/label_convert.sh -i data.csv -c label --map 'positive=1,negative=0,neutral=2' -o numeric.csv

# Map from a file
bash nlp_specific/label_convert.sh -i data.csv -c label --map-file label_map.tsv -o mapped.csv

# Sentiment-specific stats (exclamation marks, caps, etc.)
bash nlp_specific/sentiment_stats.sh -i data.csv -c label -t text

# Cohen's kappa between two annotators
bash nlp_specific/annotation_agreement.sh -a annotator1.txt -b annotator2.txt

# Convert to binary: positive vs rest
bash nlp_specific/binary_to_multiclass.sh -i data.csv -c label --to-binary --pos positive -o binary.csv

# Augment data by word shuffling (2 copies per sample)
bash nlp_specific/data_augment_shuffle.sh -i data.csv -c text -n 2 --keep-orig -o augmented.csv
```
</details>

---

### Data Quality (`data_quality/`)

| Script | Description |
|--------|-------------|
| `find_empty_lines.sh` | Find and optionally remove empty lines |
| `find_duplicates.sh` | Find duplicate rows with occurrence counts |
| `missing_values.sh` | Per-column missing value report (NULL, NA, NaN, etc.) |
| `outlier_detect.sh` | Detect text length outliers using IQR method |
| `data_profile.sh` | Comprehensive dataset profiling |
| `check_encoding.sh` | Check encoding, BOM, CRLF, null bytes |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Report empty lines
bash data_quality/find_empty_lines.sh -i corpus.txt

# Remove empty lines
bash data_quality/find_empty_lines.sh -i corpus.txt --remove -o clean.txt

# Find duplicate rows
bash data_quality/find_duplicates.sh -i data.csv

# Find duplicates in a specific column
bash data_quality/find_duplicates.sh -i data.csv -c text --top 10

# Missing value report
bash data_quality/missing_values.sh -i data.csv

# Detect text length outliers (IQR method)
bash data_quality/outlier_detect.sh -i data.csv -c text --by tokens --factor 1.5

# Full dataset profile
bash data_quality/data_profile.sh -i data.csv

# Check and fix encoding issues
bash data_quality/check_encoding.sh -i file.txt --fix -o fixed.txt
```
</details>

---

### Format Conversion (`format_conversion/`)

| Script | Description |
|--------|-------------|
| `conll_to_csv.sh` | CoNLL → CSV with sentence IDs |
| `csv_to_conll.sh` | CSV → CoNLL format |
| `bio_tags_check.sh` | Validate BIO/IOB/BIOES tag sequences |
| `fasttext_format.sh` | Bidirectional FastText ↔ CSV converter |
| `libsvm_to_csv.sh` | LibSVM sparse → dense CSV |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# CoNLL to CSV
bash format_conversion/conll_to_csv.sh -i data.conll --columns "token,pos,ner" -o data.csv

# CSV to CoNLL
bash format_conversion/csv_to_conll.sh -i data.csv --sent-col sentence_id -o data.conll

# Validate BIO tag sequences
bash format_conversion/bio_tags_check.sh -i tagged.txt --format bio

# CSV to FastText __label__ format
bash format_conversion/fasttext_format.sh --to-fasttext -i data.csv -c label -t text -o data.ft

# FastText to CSV
bash format_conversion/fasttext_format.sh --from-fasttext -i data.ft -o data.csv

# LibSVM to dense CSV
bash format_conversion/libsvm_to_csv.sh -i features.libsvm -o features.csv
```
</details>

---

### Utilities (`utils/`)

| Script | Description |
|--------|-------------|
| `file_compare.sh` | Compare two data files (size, lines, diff) |
| `batch_process.sh` | Apply any script to multiple files with progress |
| `generate_report.sh` | Generate Markdown summary report for a dataset |

<details>
<summary><strong>Sample Usage</strong></summary>

```bash
# Compare two files
bash utils/file_compare.sh -a file1.txt -b file2.txt

# Summary comparison only
bash utils/file_compare.sh -a file1.txt -b file2.txt --summary

# Batch word frequency on all .txt files
bash utils/batch_process.sh --script corpus_analysis/word_freq.sh --args '-n 10 --lower' -i *.txt --output-dir results/

# Generate a full Markdown report for a classification dataset
bash utils/generate_report.sh -i data.csv -c label -t text -o report.md
```
</details>

---

## 🔧 Design Principles

- **Pipeline-friendly**: Read stdin, write stdout — chain with `|`
- **Self-documenting**: Every script supports `--help`
- **Portable**: Standard Unix tools only, macOS + Linux compatible
- **Shared library**: `lib/common.sh` provides argument parsing, colored output, CSV detection
- **Clear authorship**: Headers and inline comments delineate original vs AI-enhanced code

---

## 📂 Sample Data

The `sample_data/` directory contains test datasets:

| File | Contents |
|------|----------|
| `sentiment.csv` | Sentiment/sarcasm classification (20 rows) |
| `multiclass.tsv` | Multi-class TSV with sublabels |
| `corpus.txt` | Mixed NLP corpus (20 sentences) |
| `parallel_en.txt` / `parallel_fr.txt` | English-French parallel corpus |
| `gold.txt` / `pred.txt` | Gold vs predicted labels for evaluation |

---

## 📝 Walkthrough — Build & Verification Log

### Verification Results

**csv_stats**
```
═══ File Statistics ═══
  File:                sentiment.csv
  Size:                1.3K (1318 bytes)
  Delimiter:           , (CSV)
  Rows:                20
  Columns:             3
```

**word_freq** (with bar chart)
```
Word Frequency
       26 the                  ██████████████████████████████
        7 in                   ████████
        6 of                   ██████
        6 and                  ██████
        4 to                   ████
```

**classification_report** (sklearn-style output)
```
Label           Precision    Recall  F1-Score   Support
negative           0.7143    1.0000    0.8333         5
neutral            0.7500    0.6000    0.6667         5
positive           0.8333    1.0000    0.9091         5
sarcasm            1.0000    0.6000    0.7500         5
accuracy                               0.8000        20
macro avg          0.8244    0.8000    0.7898        20
weighted avg       0.8244    0.8000    0.7898        20
```

**confusion_matrix**
```
Gold\Pred      negative    neutral   positive    sarcasm
negative              5          0          0          0
neutral               1          3          1          0
positive              0          0          5          0
sarcasm               1          1          0          3
Accuracy: 16/20 = 0.8000 (80.0%)
```

**parallel_check**
```
  Source lines:             15
  Target lines:             15
  ✓  Line counts match: 15
  Mean length ratio:        0.87
  Suspicious pairs:         0 (0.0%)
```

**corpus_stats**
```
═══ Corpus Statistics ═══
  Lines/sentences:          20
  Characters:               1517
  Tokens:                   230
  Types (unique):           171
  Hapax legomena:           151 (88.30% of types)
  Type-token ratio:         0.7435
  Avg word length:          5.5 chars
```

**annotation_agreement**
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

All 68 scripts verified as functional on macOS with sample data.
