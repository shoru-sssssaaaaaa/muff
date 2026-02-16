export default {
  "frontend/src/**/*.{ts,tsx}": () => "npm run lint --prefix frontend",
  "backend/src/**/*.kt": () => "cd backend && ./gradlew ktlintCheck",
};
