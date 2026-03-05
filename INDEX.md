# AegisAI Documentation Index

Complete guide to all project documentation.

##  Getting Started (Read These First)

1. **[README.md](README.md)** - Project overview and introduction
2. **[QUICKSTART.md](QUICKSTART.md)** - Get running in 5 minutes
3. **[SETUP.md](SETUP.md)** - Complete setup instructions

##  For Developers

### Flutter App
- **[flutter_app/README.md](flutter_app/README.md)** - Flutter-specific documentation
- **[flutter_app/lib/](flutter_app/lib/)** - Source code directory
  - `main.dart` - App entry point
  - `risk_engine.dart` - Risk calculation logic
  - `sensor_service.dart` - Sensor management
  - `alert_manager.dart` - SMS and backend integration
  - `storage_service.dart` - Local data persistence
  - `screens/` - UI screens (4 files)

### Django Backend
- **[django_backend/README.md](django_backend/README.md)** - Backend-specific documentation
- **[django_backend/api/](django_backend/api/)** - API source code
  - `models.py` - Database models
  - `views.py` - API endpoints
  - `serializers.py` - Data validation
  - `tests.py` - API tests

##  For Demo/Presentation

1. **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - 30-second demo script
2. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - What was delivered
3. **[VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)** - Testing checklist

##  Architecture & Design

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and data flow
2. **[DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md)** - File organization
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Commands and config cheat sheet

##  Reference Materials

### Configuration
- **[django_backend/.env.example](django_backend/.env.example)** - Environment variables
- **[flutter_app/pubspec.yaml](flutter_app/pubspec.yaml)** - Flutter dependencies
- **[django_backend/requirements.txt](django_backend/requirements.txt)** - Python dependencies

### Testing
- **[flutter_app/test/risk_engine_test.dart](flutter_app/test/risk_engine_test.dart)** - Flutter tests
- **[django_backend/api/tests.py](django_backend/api/tests.py)** - Django tests

##  Documentation by Purpose

### I want to...

#### ...understand what this project is
→ Read [README.md](README.md)

#### ...get it running quickly
→ Follow [QUICKSTART.md](QUICKSTART.md)

#### ...do a complete setup
→ Follow [SETUP.md](SETUP.md)

#### ...demo it to judges/stakeholders
→ Use [DEMO_GUIDE.md](DEMO_GUIDE.md)

#### ...understand the architecture
→ Read [ARCHITECTURE.md](ARCHITECTURE.md)

#### ...find a specific file
→ Check [DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md)

#### ...look up a command
→ Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

#### ...verify everything works
→ Follow [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md)

#### ...see what was delivered
→ Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

#### ...customize the risk engine
→ Edit `flutter_app/lib/risk_engine.dart`

#### ...change the backend URL
→ Edit `flutter_app/lib/alert_manager.dart`

#### ...modify the UI
→ Edit files in `flutter_app/lib/screens/`

#### ...add API endpoints
→ Edit `django_backend/api/views.py` and `urls.py`

#### ...change database models
→ Edit `django_backend/api/models.py`

##  Learning Path

### For New Developers
1. Read [README.md](README.md) - Overview
2. Read [ARCHITECTURE.md](ARCHITECTURE.md) - Understand design
3. Follow [SETUP.md](SETUP.md) - Get it running
4. Read [DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md) - Know where things are
5. Explore source code with inline comments

### For Reviewers/Judges
1. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - What was built
2. Follow [QUICKSTART.md](QUICKSTART.md) - See it work
3. Use [DEMO_GUIDE.md](DEMO_GUIDE.md) - Structured demo
4. Check [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) - Verify claims

### For Maintainers
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) - System design
2. Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Common tasks
3. Review inline code comments
4. Run tests to understand behavior

##  Documentation Statistics

| Document | Purpose | Length | Audience |
|----------|---------|--------|----------|
| README.md | Overview | Short | Everyone |
| QUICKSTART.md | Fast setup | Short | Developers |
| SETUP.md | Complete setup | Long | Developers |
| DEMO_GUIDE.md | Demo script | Medium | Presenters |
| ARCHITECTURE.md | System design | Long | Architects |
| DIRECTORY_STRUCTURE.md | File layout | Medium | Developers |
| QUICK_REFERENCE.md | Command cheat sheet | Medium | Developers |
| PROJECT_SUMMARY.md | Deliverables | Long | Reviewers |
| VERIFICATION_CHECKLIST.md | Testing guide | Long | QA/Testers |
| INDEX.md | This file | Medium | Everyone |

##  External Resources

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [sensors_plus Package](https://pub.dev/packages/sensors_plus)
- [geolocator Package](https://pub.dev/packages/geolocator)
- [telephony Package](https://pub.dev/packages/telephony)

### Django
- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [PostgreSQL](https://www.postgresql.org/docs/)

### Android
- [Android Permissions](https://developer.android.com/guide/topics/permissions/overview)
- [Foreground Services](https://developer.android.com/guide/components/foreground-services)

##  Document Maintenance

### Last Updated
- All documents: 2026-03-01
- Version: 1.0.0

### Update Frequency
- Code documentation: Update with code changes
- Setup guides: Update when dependencies change
- Architecture docs: Update on major design changes
- Demo guide: Update when UI changes

##  Getting Help

### Common Issues
1. Check [SETUP.md](SETUP.md) troubleshooting section
2. Check [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) for test failures
3. Review inline code comments
4. Check error messages in terminal

### Documentation Feedback
If documentation is unclear or missing information:
1. Note the specific section
2. Describe what's confusing
3. Suggest improvements

##  Documentation Completeness

- [x] Project overview
- [x] Quick start guide
- [x] Complete setup instructions
- [x] Demo script
- [x] Architecture documentation
- [x] File structure reference
- [x] Command reference
- [x] Testing checklist
- [x] Inline code comments
- [x] API documentation
- [x] Configuration examples
- [x] Troubleshooting guides

---

**Total Documentation:** 10 markdown files + inline comments

**Total Pages:** ~50 pages equivalent

**Estimated Reading Time:** 2-3 hours for complete documentation

**Quick Start Time:** 5 minutes with QUICKSTART.md
