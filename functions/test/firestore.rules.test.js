const fs = require('fs');
const path = require('path');
const {
  after,
  before,
  beforeEach,
  describe,
  it,
} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

describe('Firestore security rules', () => {
  let testEnvironment;

  before(async () => {
    testEnvironment = await initializeTestEnvironment({
      projectId: 'demo-quran-app',
      firestore: {
        rules: fs.readFileSync(
          path.join(__dirname, '..', '..', 'firestore.rules'),
          'utf8'
        ),
      },
    });
  });

  beforeEach(async () => {
    await testEnvironment.clearFirestore();
  });

  after(async () => {
    await testEnvironment.cleanup();
  });

  it('allows an owner to write valid progress', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertSucceeds(
      db.doc('users/owner/progress/12').set({
        pageNumber: 12,
        profileId: 'profile-id',
        status: 1,
        reviewCount: 0,
      })
    );
  });

  it('rejects invalid progress schema', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertFails(
      db.doc('users/owner/progress/999').set({
        pageNumber: 999,
        profileId: 'profile-id',
        status: 50,
        reviewCount: -1,
      })
    );
  });

  it('rejects access to another user data', async () => {
    const db = testEnvironment
      .authenticatedContext('attacker')
      .firestore();

    await assertFails(
      db.doc('users/owner/sessions/session-id').set({
        id: 'session-id',
      })
    );
  });

  it('rejects unknown subcollections and meta documents', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertFails(
      db.doc('users/owner/unexpected/document').set({value: true})
    );
    await assertFails(
      db.doc('users/owner/meta/unexpected').set({value: true})
    );
  });

  it('allows only valid owner session records', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertSucceeds(
      db.doc('users/owner/sessions/session-id').set({
        id: 'session-id',
        profileId: 'profile-id',
        date: '2026-06-10T12:00:00.000Z',
        durationMinutes: 25,
        sabaqCompleted: 1,
        sabqiCompleted: 0,
        manzilCompleted: 0,
        sabaqAssessment: 1,
        sabqiAssessment: null,
        manzilAssessment: null,
        sabaqPage: 12,
        sabqiPages: '10,11',
        manzilPages: '',
        repCount: 5,
      })
    );
    await assertFails(
      db.doc('users/owner/sessions/bad-session').set({
        id: 'bad-session',
        arbitraryBlob: 'x'.repeat(64),
      })
    );
    await assertFails(
      db.doc('users/owner/sessions/bad-duration').set({
        id: 'bad-duration',
        profileId: 'profile-id',
        date: '2026-06-10T12:00:00.000Z',
        durationMinutes: -5,
      })
    );
  });

  it('allows only valid owner plan records', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertSucceeds(
      db.doc('users/owner/plans/plan-id').set({
        id: 'plan-id',
        profileId: 'profile-id',
        date: '2026-06-10T00:00:00.000',
        sabaqPage: 14,
        sabaqLineStart: 1,
        sabaqLineEnd: 15,
        sabaqTargetMinutes: 25,
        sabaqRepetitionTarget: 10,
        sabaqStartVerse: null,
        sabqiPages: '12,13',
        sabqiTargetMinutes: 15,
        manzilJuz: 30,
        manzilPages: '',
        manzilRotationDay: 1,
        manzilTargetMinutes: 15,
        sabaqDoneOffline: 0,
        sabqiDoneOffline: 0,
        manzilDoneOffline: 0,
        isCompleted: 0,
        isAiGenerated: 0,
        aiReasoning: null,
      })
    );
    await assertFails(
      db.doc('users/owner/plans/bad-plan').set({
        id: 'bad-plan',
        unknownField: true,
      })
    );
  });

  it('allows only valid owner flashcard records', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertSucceeds(
      db.doc('users/owner/flashcards/card-id').set({
        id: 'card-id',
        type: 0,
        profile_id: 'profile-id',
        verse_key: '2:5',
        question_data: '{}',
        answer_data: '{}',
        interval: 1.0,
        ease_factor: 2.5,
        due_date: '2026-06-11T00:00:00.000',
        last_reviewed_at: null,
        review_count: 0,
      })
    );
    await assertFails(
      db.doc('users/owner/flashcards/bad-card').set({
        id: 'bad-card',
        payload: {nested: 'blob'},
      })
    );
  });

  it('allows only valid owner flashcard review records', async () => {
    const db = testEnvironment
      .authenticatedContext('owner')
      .firestore();

    await assertSucceeds(
      db.doc('users/owner/flashcard_reviews/review-id').set({
        id: 'review-id',
        card_id: 'card-id',
        rating: 2,
        reviewed_at: '2026-06-10T12:00:00.000Z',
      })
    );
    await assertFails(
      db.doc('users/owner/flashcard_reviews/bad-review').set({
        id: 'bad-review',
        card_id: 'card-id',
        rating: 99,
        reviewed_at: '2026-06-10T12:00:00.000Z',
      })
    );
  });
});
