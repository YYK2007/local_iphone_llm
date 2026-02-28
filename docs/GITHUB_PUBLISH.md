# Publish To GitHub

## 1) Initialize local git repo (if not already)
```bash
cd <repo-path>
git init
```

## 2) Review files that will be committed
```bash
git status
```

## 3) Create first commit
```bash
git add .
git commit -m "Initial release: on-device Qwen iPhone chat app"
```

## 4) Create empty GitHub repository
Create a new repo on GitHub (without README/license/gitignore initialization), then copy your repo URL.

## 5) Push
Replace `<YOUR_REPO_URL>` with your GitHub remote URL.

```bash
git branch -M main
git remote add origin <YOUR_REPO_URL>
git push -u origin main
```

## Optional: add tags/releases
```bash
git tag -a v1.0.0 -m "First public release"
git push origin v1.0.0
```
