# Firebase Production Setup Guide

## Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Login to Firebase: `firebase login`

## Step 1: Create Firebase Projects

### Development Project
```bash
firebase projects:create ndis-connect-dev --display-name "NDIS Connect Development"
```

### Staging Project
```bash
firebase projects:create ndis-connect-staging --display-name "NDIS Connect Staging"
```

### Production Project
```bash
firebase projects:create ndis-connect-prod --display-name "NDIS Connect Production"
```

## Step 2: Configure FlutterFire for Each Environment

### Development
```bash
cd ndis_connect
flutterfire configure --project=ndis-connect-dev --platforms=android,ios,web
```

### Staging
```bash
flutterfire configure --project=ndis-connect-staging --platforms=android,ios,web
```

### Production
```bash
flutterfire configure --project=ndis-connect-prod --platforms=android,ios,web
```

## Step 3: Set Up Firebase Services

### Authentication
1. Enable Anonymous Authentication
2. Enable Email/Password Authentication (for future use)
3. Configure authorized domains

### Firestore Database
1. Create database in production mode
2. Deploy security rules: `firebase deploy --only firestore:rules`
3. Set up indexes for queries

### Remote Config
1. Set up default values
2. Configure conditions for different environments
3. Deploy: `firebase deploy --only remoteconfig`

### Analytics
1. Enable Google Analytics
2. Configure data retention
3. Set up conversion events

### Crashlytics
1. Enable Crashlytics
2. Configure symbol uploads
3. Set up alerts

### Cloud Messaging
1. Configure APNs (iOS)
2. Set up FCM tokens
3. Configure message templates

## Step 4: Security Configuration

### Firestore Security Rules
Deploy the rules from `firebase/firestore.rules`:
```bash
firebase deploy --only firestore:rules
```

### Storage Security Rules
Create and deploy storage rules:
```bash
firebase deploy --only storage
```

## Step 5: Environment Configuration

Update `lib/config/environment.dart` with actual project IDs:
- Development: `ndis-connect-dev`
- Staging: `ndis-connect-staging`
- Production: `ndis-connect-prod`

## Step 6: Testing

### Local Testing
```bash
firebase emulators:start
```

### Deploy to Staging
```bash
firebase use ndis-connect-staging
firebase deploy
```

### Deploy to Production
```bash
firebase use ndis-connect-prod
firebase deploy
```

## Step 7: Monitoring Setup

### Set up Alerts
1. Firebase Console > Project Settings > Monitoring
2. Configure alerts for:
   - High error rates
   - Unusual traffic patterns
   - Cost thresholds

### Performance Monitoring
1. Enable Performance Monitoring
2. Set up custom traces
3. Configure alerts

## Step 8: Backup and Recovery

### Firestore Backup
```bash
gcloud firestore export gs://ndis-connect-prod-backups/$(date +%Y%m%d)
```

### Automated Backups
Set up Cloud Scheduler for daily backups.

## Security Checklist

- [ ] Firestore security rules deployed
- [ ] Storage security rules deployed
- [ ] Authentication methods configured
- [ ] API keys restricted to app domains
- [ ] Data encryption enabled
- [ ] Privacy settings configured
- [ ] Access logging enabled
- [ ] Backup strategy implemented

## Cost Management

- [ ] Set up billing alerts
- [ ] Configure usage quotas
- [ ] Monitor daily costs
- [ ] Optimize Firestore queries
- [ ] Implement data archiving strategy

## Compliance

- [ ] Data retention policies configured
- [ ] Privacy policy updated
- [ ] GDPR compliance measures
- [ ] Australian Privacy Act compliance
- [ ] NDIS data handling requirements
