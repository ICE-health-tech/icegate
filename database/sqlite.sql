-- SQLite Complete Setup (.sqli format)
-- This file contains both the CREATE TABLE statements and the initial INSERT seed data.

-- 1. TABLES
CREATE TABLE IF NOT EXISTS internal_widgets (
    internal_widget_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    url TEXT,
    date_added TEXT NOT NULL,
    image_url TEXT NOT NULL,
    alias TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS external_widgets (
    widget_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    alias TEXT,
    protocol TEXT NOT NULL,
    host TEXT NOT NULL,
    url TEXT NOT NULL,
    image_url TEXT,
    date_added TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS themes (
    themeID INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    alias TEXT NOT NULL UNIQUE,
    json_content TEXT NOT NULL,
    author TEXT NOT NULL,
    addedDate TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS persons (
    personID INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName TEXT,
    dateOfBirth TEXT,
    gender TEXT,
    phoneNumber TEXT,
    profileImageUrl TEXT,
    relationship TEXT DEFAULT 'none',
    affection INTEGER DEFAULT 0,
    isActive BOOLEAN DEFAULT 1,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS email_addresses (
    emailAddressID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    emailAddress TEXT NOT NULL,
    emailType TEXT DEFAULT 'personal',
    isPrimary BOOLEAN DEFAULT 0,
    status TEXT DEFAULT 'pending',
    verifiedAt TEXT,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_accounts (
    accountID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    passwordHash TEXT NOT NULL,
    primaryEmailID INTEGER REFERENCES email_addresses(emailAddressID),
    role TEXT DEFAULT 'user',
    isLocked BOOLEAN DEFAULT 0,
    failedLoginAttempts INTEGER DEFAULT 0,
    lastLoginAt TEXT,
    passwordChangedAt TEXT DEFAULT CURRENT_TIMESTAMP,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS profiles (
    profileID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER UNIQUE REFERENCES persons(personID) ON DELETE CASCADE,
    bio TEXT,
    occupation TEXT,
    educationLevel TEXT,
    location TEXT,
    websiteUrl TEXT,
    linkedinUrl TEXT,
    githubUrl TEXT,
    timezone TEXT DEFAULT 'UTC',
    preferredLanguage TEXT DEFAULT 'en',
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
    name TEXT
);

CREATE TABLE IF NOT EXISTS projects (
    projectID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    color TEXT,
    status INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS project_notes (
    noteID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
    projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS skills (
    skillID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    skillName TEXT NOT NULL,
    skillCategory TEXT,
    proficiencyLevel TEXT DEFAULT 'beginner',
    yearsOfExperience INTEGER DEFAULT 0,
    description TEXT,
    isFeatured BOOLEAN DEFAULT 0,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS financial_accounts (
    accountID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    accountName TEXT NOT NULL,
    accountType TEXT DEFAULT 'checking',
    balance REAL DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    isPrimary BOOLEAN DEFAULT 0,
    isActive BOOLEAN DEFAULT 1,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets (
    assetID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    assetName TEXT NOT NULL,
    assetCategory TEXT NOT NULL,
    purchaseDate TEXT,
    purchasePrice REAL,
    currentEstimatedValue REAL,
    currency TEXT DEFAULT 'USD',
    condition TEXT DEFAULT 'good',
    location TEXT,
    notes TEXT,
    isInsured BOOLEAN DEFAULT 0,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions (
    transactionID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    category TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    transactionDate TEXT DEFAULT CURRENT_TIMESTAMP,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS goals (
    goalID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'personal',
    priority INTEGER DEFAULT 3,
    status TEXT DEFAULT 'active',
    targetDate TEXT,
    completionDate TEXT,
    progressPercentage INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
    projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS scores (
    scoreID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER UNIQUE REFERENCES persons(personID) ON DELETE CASCADE,
    healthGlobalScore REAL DEFAULT 0.0,
    socialGlobalScore REAL DEFAULT 0.0,
    financialGlobalScore REAL DEFAULT 0.0,
    careerGlobalScore REAL DEFAULT 0.0,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS habits (
    habitID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    goalID INTEGER REFERENCES goals(goalID) ON DELETE SET NULL,
    habitName TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    frequencyDetails TEXT,
    targetCount INTEGER DEFAULT 1,
    isActive BOOLEAN DEFAULT 1,
    startedDate TEXT DEFAULT CURRENT_TIMESTAMP,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS blog_posts (
    postID INTEGER PRIMARY KEY AUTOINCREMENT,
    authorID INTEGER REFERENCES persons(personID),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT,
    content TEXT NOT NULL,
    featuredImageUrl TEXT,
    status TEXT DEFAULT 'draft',
    isFeatured BOOLEAN DEFAULT 0,
    viewCount INTEGER DEFAULT 0,
    likeCount INTEGER DEFAULT 0,
    publishedAt TEXT,
    scheduledFor TEXT,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS person_widgets (
    personWidgetID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    widgetName TEXT NOT NULL,
    widgetType TEXT NOT NULL,
    configuration TEXT DEFAULT '{}',
    displayOrder INTEGER DEFAULT 0,
    isActive BOOLEAN DEFAULT 1,
    role TEXT DEFAULT 'admin',
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS health_metrics (
    metricID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    date TEXT NOT NULL,
    steps INTEGER DEFAULT 0,
    heartRate INTEGER DEFAULT 0,
    sleepHours REAL DEFAULT 0.0,
    waterGlasses INTEGER DEFAULT 0,
    exerciseMinutes INTEGER DEFAULT 0,
    weightKg REAL DEFAULT 0.0,
    caloriesConsumed INTEGER DEFAULT 0,
    caloriesBurned INTEGER DEFAULT 0,
    updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(personID, date)
);

CREATE TABLE IF NOT EXISTS meals (
    meal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mealName TEXT NOT NULL,
    mealImageUrl TEXT,
    fat REAL DEFAULT 0.0,
    carbs REAL DEFAULT 0.0,
    protein REAL DEFAULT 0.0,
    calories REAL DEFAULT 0.0,
    eatenAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS days (
    day_id TEXT PRIMARY KEY,
    weight INTEGER DEFAULT 0,
    caloriesOut INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS session_table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    jwt TEXT NOT NULL,
    username TEXT,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS water_logs (
    logID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sleep_logs (
    logID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    startTime TEXT NOT NULL,
    endTime TEXT,
    quality INTEGER DEFAULT 3
);

CREATE TABLE IF NOT EXISTS exercise_logs (
    logID INTEGER PRIMARY KEY AUTOINCREMENT,
    personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE,
    type TEXT NOT NULL,
    durationMinutes INTEGER NOT NULL,
    intensity TEXT DEFAULT 'medium',
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS theme_table (
    themeID INTEGER PRIMARY KEY AUTOINCREMENT,
    themeName TEXT NOT NULL,
    themePath TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS custom_notifications (
    notificationID INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    scheduledTime TEXT NOT NULL,
    repeatFrequency TEXT DEFAULT 'none',
    repeatDays TEXT,
    isEnabled BOOLEAN DEFAULT 1,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quotes (
    logID INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    author TEXT,
    isActive BOOLEAN DEFAULT 1,
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. SEED DATA
-- Insert Person (ID 1)
INSERT INTO persons (personID, firstName, lastName, dateOfBirth, gender, phoneNumber, profileImageUrl) 
VALUES (1, 'Long', 'Duy', '1995-01-01', 'Male', '+84 123 456 789', 'https://example.com/avatar.jpg');

-- Insert Email
INSERT INTO email_addresses (personID, emailAddress, emailType, isPrimary, status) 
VALUES (1, 'long@example.com', 'personal', 1, 'verified');

-- Insert Account
INSERT INTO user_accounts (personID, username, passwordHash, role) 
VALUES (1, 'duylong', 'hashed_password', 'admin');

-- Insert Profile
INSERT INTO profiles (personID, bio, occupation, educationLevel, location, websiteUrl, name) 
VALUES (1, 'Flutter Developer & Tech Enthusiast', 'Software Engineer', 'Bachelor', 'Ho Chi Minh City, Vietnam', 'https://duylong.dev', 'Long Duy');

-- Insert Financial Accounts
INSERT INTO financial_accounts (personID, accountName, accountType, balance, currency, isPrimary) 
VALUES (1, 'Main Checking', 'checking', 1500.00, 'USD', 1);
INSERT INTO financial_accounts (personID, accountName, accountType, balance, currency) 
VALUES (1, 'Savings', 'savings', 5000.00, 'USD');

-- Insert Assets
INSERT INTO assets (personID, assetName, assetCategory, currentEstimatedValue, currency) 
VALUES (1, 'MacBook Pro', 'electronics', 2000.00, 'USD');

-- Insert Skills
INSERT INTO skills (personID, skillName, proficiencyLevel, yearsOfExperience, isFeatured) 
VALUES (1, 'Flutter', 'expert', 4, 1);

-- Insert Blog Posts
INSERT INTO blog_posts (authorID, title, slug, content, status, publishedAt) 
VALUES (1, 'Hello World', 'hello-world', 'This is my first post on the new platform.', 'published', CURRENT_TIMESTAMP);

