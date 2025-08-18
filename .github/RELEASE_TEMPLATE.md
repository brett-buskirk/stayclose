# StayClose Release Template

Use this template when creating new releases for StayClose.

## Release Types

### Major Release (0.X.0+N)
- New features or significant changes
- Breaking changes or major UI updates
- New app functionality

### Minor Release (0.2.X+N)  
- Feature additions or enhancements
- Non-breaking improvements
- New settings or options

### Patch/Hotfix (0.2.2+N)
- Bug fixes
- Critical issues resolved
- Security patches

## Release Command Template

```bash
gh release create v[VERSION] --title "StayClose v[VERSION] - [FEATURE_NAME]" --notes "$(cat <<'EOF'
## [EMOJI] [RELEASE_TYPE]: [BRIEF_DESCRIPTION]

[Detailed description of what this release accomplishes]

### [Changes Section - choose appropriate]

#### ✨ New Features (for minor/major releases)
- New feature description
- Another new feature

#### 🔧 Bug Fixes (for patches/hotfixes)
- Fixed issue with [specific problem]
- Resolved [another issue]

#### 🛠️ Improvements (for any release type)
- Enhanced [specific area]
- Improved [performance/UI/etc.]

#### 📱 Technical Changes (optional - for significant changes)
- Updated [dependency/framework]
- Refactored [component]
- Added [technical improvement]

### Testing
- ✅ [Specific test performed]
- ✅ [Another test result]
- ✅ [Platform compatibility confirmed]

### Deployment
**Target**: Google Play Console ([Testing Phase])  
**Priority**: [Normal/High/Critical]  
**Commits**: [START_COMMIT] → [END_COMMIT]

---
🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

## Examples by Release Type

### Major Release Example
```bash
gh release create v1.0.0+10 --title "StayClose v1.0.0 - Production Launch" --notes "..."
```

### Minor Release Example  
```bash
gh release create v0.3.0+8 --title "StayClose v0.3.0 - Contact Groups" --notes "..."
```

### Patch/Hotfix Example
```bash
gh release create v0.2.3+9 --title "StayClose v0.2.3 - Notification Fix" --notes "..."
```

## Emojis for Release Types

- 🚀 Major Release
- ✨ New Features
- 🔧 Bug Fixes / Hotfix
- 🛠️ Improvements
- 📱 Mobile Specific
- 🔐 Security Updates
- ⚡ Performance
- 🎨 UI/UX Updates

## Quick Reference

1. **Update version** in `pubspec.yaml`
2. **Commit and push** changes
3. **Run release command** with appropriate template
4. **Update Google Play** with same version
5. **Update CLAUDE.md** if needed