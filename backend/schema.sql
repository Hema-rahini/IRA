-- ==========================================================
-- IRA Wellness & Cognitive Behavioral Therapy Database Schema
-- Database: `ira`
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `ira` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ira`;

-- ----------------------------------------------------------
-- 1. Patients / Signup Details Table
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `signup_details` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `Name` VARCHAR(100) NOT NULL,
  `Mobile_No` VARCHAR(15) NOT NULL UNIQUE,
  `Email_ID` VARCHAR(80) NOT NULL UNIQUE,
  `password_hash` VARCHAR(120) NOT NULL,
  `Age` FLOAT DEFAULT NULL,
  `Height` FLOAT DEFAULT NULL,
  `Weight` FLOAT DEFAULT NULL,
  `Gender` VARCHAR(10) DEFAULT NULL,
  `Occupation` VARCHAR(50) DEFAULT NULL,
  `ProfileImage` VARCHAR(100) DEFAULT NULL,
  `fcm_token` VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 2. Doctor Credentials Table
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `doctor` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password` VARCHAR(200) NOT NULL,
  `profile_image` VARCHAR(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 3. Login / Signout Activity Audit Log
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `login_signout_activity` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL,
  `login_time` TIMESTAMP NULL DEFAULT NULL,
  `signout_time` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 4. Consultation Chat Messages
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `text` VARCHAR(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 5. Daily Diary / Thoughts & AI Sentiment Analysis
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `thoughts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `Email_ID` VARCHAR(50) NOT NULL,
  `thoughts` VARCHAR(100) NOT NULL,
  `received_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `Output` VARCHAR(10) DEFAULT 'null'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 6. Emotional Assessment & Anger Scale Scores
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `score` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(50) NOT NULL UNIQUE,
  `negativecount` INT DEFAULT 0,
  `positivecount` INT DEFAULT 0,
  `joyful` INT DEFAULT 0,
  `happy` INT DEFAULT 0,
  `amazed` INT DEFAULT 0,
  `depression` INT DEFAULT 0,
  `chill` INT DEFAULT 0,
  `miserable` INT DEFAULT 0,
  `furious` INT DEFAULT 0,
  `irritated` INT DEFAULT 0,
  `manic` INT DEFAULT 0,
  `calm` INT DEFAULT 0,
  `score_1` INT DEFAULT NULL,
  `score_1_date` DATE DEFAULT NULL,
  `anger_scale_1` VARCHAR(50) DEFAULT NULL,
  `score_2` INT DEFAULT NULL,
  `score_2_date` DATE DEFAULT NULL,
  `anger_scale_2` VARCHAR(50) DEFAULT NULL,
  `firstPssScale` VARCHAR(50) DEFAULT NULL,
  `firstPssScaleDate` DATE DEFAULT NULL,
  `SecondPssScale` VARCHAR(50) DEFAULT NULL,
  `SecondPssScaleDate` DATE DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- 7. 13-Day Cognitive Behavioral Therapy Roadmap
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `Activity` (
  `email` VARCHAR(50) NOT NULL PRIMARY KEY,
  `angerscale` VARCHAR(50) DEFAULT NULL,
  `Day1_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day1_Activity_1_s` INT DEFAULT 0,
  `Day1_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day1_Activity_2_s` INT DEFAULT 0,
  `Day2_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day2_Activity_1_s` INT DEFAULT 0,
  `Day2_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day2_Activity_2_s` INT DEFAULT 0,
  `Day3_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day3_Activity_1_s` INT DEFAULT 0,
  `Day3_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day3_Activity_2_s` INT DEFAULT 0,
  `Day4_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day4_Activity_1_s` INT DEFAULT 0,
  `Day4_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day4_Activity_2_s` INT DEFAULT 0,
  `Day5_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day5_Activity_1_s` INT DEFAULT 0,
  `Day5_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day5_Activity_2_s` INT DEFAULT 0,
  `Day6_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day6_Activity_1_s` INT DEFAULT 0,
  `Day6_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day6_Activity_2_s` INT DEFAULT 0,
  `Day7_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day7_Activity_1_s` INT DEFAULT 0,
  `Day7_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day7_Activity_2_s` INT DEFAULT 0,
  `Day8_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day8_Activity_1_s` INT DEFAULT 0,
  `Day8_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day8_Activity_2_s` INT DEFAULT 0,
  `Day9_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day9_Activity_1_s` INT DEFAULT 0,
  `Day9_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day9_Activity_2_s` INT DEFAULT 0,
  `Day10_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day10_Activity_1_s` INT DEFAULT 0,
  `Day10_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day10_Activity_2_s` INT DEFAULT 0,
  `Day11_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day11_Activity_1_s` INT DEFAULT 0,
  `Day11_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day11_Activity_2_s` INT DEFAULT 0,
  `Day12_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day12_Activity_1_s` INT DEFAULT 0,
  `Day12_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day12_Activity_2_s` INT DEFAULT 0,
  `Day13_Activity_1` VARCHAR(50) DEFAULT NULL,
  `Day13_Activity_1_s` INT DEFAULT 0,
  `Day13_Activity_2` VARCHAR(50) DEFAULT NULL,
  `Day13_Activity_2_s` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------
-- Initial Seed Data: Doctor & Demo Accounts
-- ----------------------------------------------------------
INSERT IGNORE INTO `doctor` (`id`, `name`, `email`, `password`, `profile_image`) 
VALUES (1, 'Dr. Dinesh', 'doctor@hospital.com', '$2b$12$e6N1j/V0s1rPj4QcEw8w1Om0WqjK3hF4rN9dG8sL1m2oP3qR4sT5u', 'dinesh_gmail_com.jpg');
