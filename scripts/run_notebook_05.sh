#!/usr/bin/env bash
# Re-executes notebook 05 (needs xgboost) and saves the outputs inside the notebook.
set -e
cd "$(dirname "$0")/.."
pip install -r requirements.txt nbconvert
cd notebooks
jupyter nbconvert --to notebook --execute --inplace 05_machine_learning.ipynb --ExecutePreprocessor.timeout=1800
echo "Done: outputs saved in notebooks/05_machine_learning.ipynb"
