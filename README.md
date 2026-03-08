# Vibeslinger

An interactive visual tutorial demonstrating how AI inference works, built with Flutter. Choose models, plan your approach (aim, scout, load tools), manage your context window, and fire to see how accuracy emerges from the interplay of these systems.

**Live demo:** https://nicholasspencer.github.io/vibeslinger/

## Development

```bash
flutter run -d macos    # Run locally (macOS)
flutter run -d chrome   # Run locally (web)
flutter test            # Run tests
```

## Deploying to GitHub Pages

Build with the correct base href and push to the `gh-pages` branch:

```bash
# Build
flutter build web --release --base-href /vibeslinger/

# Deploy
git fetch origin gh-pages
git worktree add /tmp/gh-pages-deploy origin/gh-pages
cd /tmp/gh-pages-deploy
git checkout -b gh-pages 2>/dev/null || git checkout gh-pages
rm -rf *
cp -r <project-root>/build/web/* .
git add -A
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages

# Cleanup
cd <project-root>
git worktree remove /tmp/gh-pages-deploy
```

GitHub Pages is configured to serve from the `gh-pages` branch root.
