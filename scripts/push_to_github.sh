#!/usr/bin/env bash
# Usage: ./scripts/push_to_github.sh <your-github-username>
# First create an EMPTY repo named waze-user-churn-prediction on github.com.
set -e
cd "$(dirname "$0")/.."
USER_NAME="${1:?Usage: $0 <github-username>}"
sed -i.bak "s/your-username/$USER_NAME/g" README.md && rm -f README.md.bak
git init
git add .
git commit -m "Waze user churn prediction: full PACE project"
git branch -M main
git remote add origin "https://github.com/$USER_NAME/waze-user-churn-prediction.git"
git push -u origin main
