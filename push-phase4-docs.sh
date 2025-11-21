#!/bin/bash
# Push Script - Phase 4: Documentation & Final Files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║     📚 Push Phase 4: Documentation                ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Check git status
echo -e "${YELLOW}🔍 Checking git status...${NC}"
git status
echo ""

# Ask for confirmation
echo -e "${YELLOW}📋 Phase 4 will include:${NC}"
echo "  • Main README.md"
echo "  • All documentation files"
echo "  • Testing guides"
echo "  • Checklists"
echo "  • Configuration guides"
echo "  • .gitignore and other config files"
echo ""

read -p "Continue with Phase 4 push? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Push cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📚 Step 1: Adding main README...${NC}"
git add README.md
echo -e "${GREEN}✅ README.md added${NC}"

echo ""
echo -e "${YELLOW}📚 Step 2: Adding documentation files...${NC}"
git add QUICKSTART.md
git add SETUP-GUIDE.md
git add TEST-ALL-PHASES.md
git add GIT-PUSH-GUIDE.md
git add PHASE3-SUMMARY.md
git add PHASE3-QUICKSTART.md
git add IMPLEMENTATION-SUMMARY.md
git add TESTING-GUIDE.md
git add ENV-CONFIGURATION.md
echo -e "${GREEN}✅ Documentation files added${NC}"

echo ""
echo -e "${YELLOW}📚 Step 3: Adding checklists...${NC}"
git add CHECKLIST.md 2>/dev/null || true
git add TESTING-CHECKLIST.md 2>/dev/null || true
git add PHASE2-COMPLETE-CHECKLIST.md 2>/dev/null || true
git add PHASE3-COMPLETE-CHECKLIST.md 2>/dev/null || true
echo -e "${GREEN}✅ Checklists added${NC}"

echo ""
echo -e "${YELLOW}📚 Step 4: Adding delivery documents...${NC}"
git add PHASE2-DELIVERY.md 2>/dev/null || true
git add PHASE2-COMPLETE.md 2>/dev/null || true
echo -e "${GREEN}✅ Delivery docs added${NC}"

echo ""
echo -e "${YELLOW}📚 Step 5: Adding configuration files...${NC}"
git add .gitignore
git add quick-commands.sh 2>/dev/null || true
git add *.sln 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true
echo -e "${GREEN}✅ Configuration files added${NC}"

echo ""
echo -e "${YELLOW}📚 Step 6: Adding push scripts...${NC}"
git add push-phase1.sh
git add push-phase2.sh
git add push-phase3.sh
git add push-phase4-docs.sh
chmod +x push-*.sh
echo -e "${GREEN}✅ Push scripts added${NC}"

echo ""
echo -e "${YELLOW}📊 Files to be committed:${NC}"
git status --short
echo ""

read -p "Proceed with commit? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Commit cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}💾 Committing Phase 4...${NC}"
git commit -m "docs: comprehensive documentation and guides

📖 Documentation Added:
- Complete README with all phases
- Quick start guide for fast setup
- Detailed setup guide with best practices
- Phase-by-phase testing guide (TEST-ALL-PHASES.md)
- Git workflow guide (GIT-PUSH-GUIDE.md)
- Implementation summary

📋 Testing & Guides:
- Automated test script (test-phase1.sh)
- Complete testing checklist
- Environment configuration guide
- Troubleshooting procedures
- Deployment instructions

✅ Checklists:
- Phase 2 completion checklist
- Phase 3 completion checklist
- Testing checklist
- Submission checklist

🎯 Project Structure:
- Clear phase organization
- Step-by-step instructions
- Trade-off documentation
- Architecture decisions documented

🔧 Scripts Added:
- Phase-specific push scripts (push-phase1.sh, push-phase2.sh, etc.)
- Quick command shortcuts
- Automated deployment helpers

📚 Complete Documentation Suite:
- All phases documented
- Clear setup instructions
- Production-ready guides
- Best practices included

✨ All phases documented
✨ Ready for submission
✨ Complete project portfolio
✨ Professional presentation"

echo -e "${GREEN}✅ Commit successful${NC}"

echo ""
echo -e "${YELLOW}🚀 Pushing to GitHub...${NC}"

# Detect branch (main or master)
BRANCH=$(git branch --show-current)
echo -e "${BLUE}   Branch: $BRANCH${NC}"

git push origin "$BRANCH"

echo -e "${GREEN}✅ Push successful!${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║     🎉 All Phases Successfully Pushed!            ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📚 Phase 4 (Documentation) is now on GitHub!${NC}"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          📊 Complete Push Summary                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Phase 1:${NC} Docker Compose implementation"
echo -e "${GREEN}✅ Phase 2:${NC} Kubernetes & Terraform infrastructure"
echo -e "${GREEN}✅ Phase 3:${NC} CI/CD pipeline & automation"
echo -e "${GREEN}✅ Phase 4:${NC} Complete documentation"
echo ""
echo -e "${YELLOW}🌐 Repository Links:${NC}"
echo -e "   Main: ${BLUE}https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra${NC}"
echo -e "   Actions: ${BLUE}https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra/actions${NC}"
echo -e "   Packages: ${BLUE}https://github.com/omarMohamedo-o?tab=packages${NC}"
echo ""
echo -e "${YELLOW}📝 Final Verification Checklist:${NC}"
echo "  [ ] All files visible on GitHub"
echo "  [ ] CI/CD workflows running"
echo "  [ ] Docker images in GHCR"
echo "  [ ] README displays correctly"
echo "  [ ] Documentation is complete"
echo "  [ ] Security scans passing"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "  1. Visit GitHub and verify all files"
echo "  2. Check Actions tab for workflow status"
echo "  3. Review README on GitHub"
echo "  4. Test clone in new directory"
echo "  5. Create release tag (git tag v1.0.0)"
echo "  6. Record demo video"
echo "  7. Submit project!"
echo ""
echo -e "${GREEN}🎉 Project ready for submission! 🎉${NC}"
echo ""
