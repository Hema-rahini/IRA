-- ==========================================================
-- IRA Wellness & Cognitive Behavioral Therapy Database Schema & Data
-- Database: `ira`
-- Exported on: 2026-10-22 09:50:58
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `ira` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ira`;

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------
-- 1. Table Structure for `signup_details`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `signup_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) NOT NULL,
  `Mobile_No` varchar(15) NOT NULL,
  `Email_ID` varchar(80) NOT NULL,
  `password_hash` varchar(120) NOT NULL,
  `Age` float DEFAULT NULL,
  `Height` float DEFAULT NULL,
  `Weight` float DEFAULT NULL,
  `Gender` varchar(10) DEFAULT NULL,
  `Occupation` varchar(50) DEFAULT NULL,
  `ProfileImage` varchar(100) DEFAULT NULL,
  `fcm_token` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Mobile_No` (`Mobile_No`),
  UNIQUE KEY `Email_ID` (`Email_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `signup_details` (6 records)
INSERT INTO `signup_details` (`id`, `Name`, `Mobile_No`, `Email_ID`, `password_hash`, `Age`, `Height`, `Weight`, `Gender`, `Occupation`, `ProfileImage`, `fcm_token`) VALUES
  (1, 'Arul Mani', '9876543210', 'arul@gmail.com', '$2b$12$UvLGOvKxkjbcjV6njPU16ezi8VTK36J93/MVUDlel/cnHjcRuInMW', 25.0, 170.0, 75.0, 'Male', 'student', 'arul@gmail.com.jpg', NULL),
  (2, 'Mani', '7895462130', 'mani@gmail.com', '$2b$12$8xDCUqboP8CVsVCFmedfpOGZaHUYO4WZ.cYOq4HYa.gE4V7981Kt.', 25.0, 180.0, 75.0, 'Male', 'Co begger', 'mani@gmail.com.jpg', NULL),
  (3, 'Gopal', '9874563210', 'gopal@gmail.com', '$2b$12$Aclvirmtt2keZa77u2XAF.xCUMci1O6Fdx/FYuLYnANMUEA3N.GAi', 30.0, 170.0, 75.0, 'Male', 'Teaching', 'gopal@gmail.com.jpg', NULL),
  (7, 'Rohith', '8974562130', 'sp@gmail.com', '$2b$12$8eXX3Z7x09NcRTuOy3DlQOaMzs4rQAOvFct8EaW.GsLW7uIs6GLTW', 20.0, 170.0, 70.0, 'Male', 'Dev', 'sp@gmail.com.jpg', NULL),
  (8, 'Ram', '9898765432', 'ram@gmail.com', '$2b$12$KLpLmGAKcGLBd6.gkpFIPOYbbSU.LbDyLg/FACdDJsA5UjgxWD1Py', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  (9, 'Hema', '8122792759', 'patient@gmail.com', '$2b$12$lY7AlXdRQT6GymScbPb3Pub8x8v7JnJ0kQLWN1FzNck2hYIwp4nji', 22.0, 160.0, 50.0, 'Female', 'Student ', 'patient@gmail.com.jpg', NULL);

-- ----------------------------------------------------------
-- 2. Table Structure for `doctor`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `doctor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(200) NOT NULL,
  `profile_image` varchar(200) DEFAULT NULL,
  `age` int(11) DEFAULT 38,
  `gender` varchar(20) DEFAULT 'Male',
  `experience` varchar(50) DEFAULT '10 Years',
  `contact` varchar(30) DEFAULT '+91 98765 43210',
  `status` varchar(20) DEFAULT 'Active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `doctor` (1 records)
INSERT INTO `doctor` (`id`, `name`, `email`, `password`, `profile_image`, `age`, `gender`, `experience`, `contact`, `status`) VALUES
  (1, 'Dr. Dinesh', 'doctor@hospital.com', '$2b$12$e6N1j/V0s1rPj4QcEw8w1Om0WqjK3hF4rN9dG8sL1m2oP3qR4sT5u', 'dinesh_gmail_com.jpg', 38, 'Male', '10 Years', '+91 98765 43210', 'Active');

-- ----------------------------------------------------------
-- 3. Table Structure for `login_signout_activity`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `login_signout_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `login_time` timestamp NULL DEFAULT NULL,
  `signout_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `login_signout_activity` (6 records)
INSERT INTO `login_signout_activity` (`id`, `email`, `login_time`, `signout_time`) VALUES
  (1, 'arul@gmail.com', '2026-10-20 15:04:47', '2026-10-20 13:48:27'),
  (2, 'mani@gmail.com', '2026-10-20 12:41:00', '2026-10-20 12:52:40'),
  (3, 'doctor@gmail.com', NULL, '2026-10-20 12:40:42'),
  (4, 'gopal@gmail.com', '2026-10-20 13:54:51', '2026-10-20 13:54:57'),
  (5, 'sp@gmail.com', '2026-10-22 09:08:30', '2026-10-21 16:18:49'),
  (6, 'patient@gmail.com', '2026-10-22 09:07:27', '2026-10-21 13:03:23');

-- ----------------------------------------------------------
-- 4. Table Structure for `chat`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `chat` (0 records)
-- (No records in `chat`)

-- ----------------------------------------------------------
-- 5. Table Structure for `thoughts`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `thoughts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Email_ID` varchar(50) NOT NULL,
  `thoughts` varchar(100) NOT NULL,
  `received_time` datetime DEFAULT current_timestamp(),
  `Output` varchar(10) DEFAULT 'null',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `thoughts` (3 records)
INSERT INTO `thoughts` (`id`, `Email_ID`, `thoughts`, `received_time`, `Output`) VALUES
  (1, 'patient@gmail.com', 'Today was a wonderful and peaceful day. I felt so relaxed and happy!', '2026-10-21 14:47:25', 'POSITIVE'),
  (2, 'patient@gmail.com', 'I was really irritated and angry when my colleague shouted at me.', '2026-10-21 14:47:25', 'NEGATIVE'),
  (3, 'sp@gmail.com', 'happy day', '2026-10-21 14:51:48', 'POSITIVE');

-- ----------------------------------------------------------
-- 6. Table Structure for `score`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `score` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(50) NOT NULL,
  `negativecount` int(11) DEFAULT 0,
  `positivecount` int(11) DEFAULT 0,
  `joyful` int(11) DEFAULT 0,
  `happy` int(11) DEFAULT 0,
  `amazed` int(11) DEFAULT 0,
  `depression` int(11) DEFAULT 0,
  `chill` int(11) DEFAULT 0,
  `miserable` int(11) DEFAULT 0,
  `furious` int(11) DEFAULT 0,
  `irritated` int(11) DEFAULT 0,
  `manic` int(11) DEFAULT 0,
  `calm` int(11) DEFAULT 0,
  `score_1` int(11) DEFAULT NULL,
  `score_1_date` date DEFAULT NULL,
  `anger_scale_1` varchar(50) DEFAULT NULL,
  `score_2` int(11) DEFAULT NULL,
  `score_2_date` date DEFAULT NULL,
  `anger_scale_2` varchar(50) DEFAULT NULL,
  `firstPssScale` varchar(50) DEFAULT NULL,
  `firstPssScaleDate` date DEFAULT NULL,
  `SecondPssScale` varchar(50) DEFAULT NULL,
  `SecondPssScaleDate` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `score` (6 records)
INSERT INTO `score` (`id`, `email`, `negativecount`, `positivecount`, `joyful`, `happy`, `amazed`, `depression`, `chill`, `miserable`, `furious`, `irritated`, `manic`, `calm`, `score_1`, `score_1_date`, `anger_scale_1`, `score_2`, `score_2_date`, `anger_scale_2`, `firstPssScale`, `firstPssScaleDate`, `SecondPssScale`, `SecondPssScaleDate`) VALUES
  (1, 'arul@gmail.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '2026-10-20', 'Contact Doctor', NULL, '2026-11-01', NULL, NULL, NULL, NULL, NULL),
  (2, 'mani@gmail.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, '2026-10-20', 'Sever Anger', NULL, '2026-11-01', NULL, NULL, NULL, NULL, NULL),
  (3, 'gopal@gmail.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, '2026-10-20', 'Sever Anger', NULL, '2026-11-01', NULL, NULL, NULL, NULL, NULL),
  (4, 'sp@gmail.com', 0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 0, 0, 47, '2026-10-20', 'Sever Anger', NULL, '2026-11-01', NULL, NULL, NULL, NULL, NULL),
  (7, 'test@test.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 15, '2026-10-21', 'Mild Anger', NULL, NULL, NULL, NULL),
  (8, 'patient@gmail.com', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 38, NULL, 'Sever Anger', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- ----------------------------------------------------------
-- 7. Table Structure for `activity`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `activity` (
  `email` varchar(50) NOT NULL,
  `angerscale` varchar(50) DEFAULT NULL,
  `Day1_Activity_1` varchar(50) DEFAULT NULL,
  `Day1_Activity_1_s` int(11) DEFAULT 0,
  `Day1_Activity_2` varchar(50) DEFAULT NULL,
  `Day1_Activity_2_s` int(11) DEFAULT 0,
  `Day2_Activity_1` varchar(50) DEFAULT NULL,
  `Day2_Activity_1_s` int(11) DEFAULT 0,
  `Day2_Activity_2` varchar(50) DEFAULT NULL,
  `Day2_Activity_2_s` int(11) DEFAULT 0,
  `Day3_Activity_1` varchar(50) DEFAULT NULL,
  `Day3_Activity_1_s` int(11) DEFAULT 0,
  `Day3_Activity_2` varchar(50) DEFAULT NULL,
  `Day3_Activity_2_s` int(11) DEFAULT 0,
  `Day4_Activity_1` varchar(50) DEFAULT NULL,
  `Day4_Activity_1_s` int(11) DEFAULT 0,
  `Day4_Activity_2` varchar(50) DEFAULT NULL,
  `Day4_Activity_2_s` int(11) DEFAULT 0,
  `Day5_Activity_1` varchar(50) DEFAULT NULL,
  `Day5_Activity_1_s` int(11) DEFAULT 0,
  `Day5_Activity_2` varchar(50) DEFAULT NULL,
  `Day5_Activity_2_s` int(11) DEFAULT 0,
  `Day6_Activity_1` varchar(50) DEFAULT NULL,
  `Day6_Activity_1_s` int(11) DEFAULT 0,
  `Day6_Activity_2` varchar(50) DEFAULT NULL,
  `Day6_Activity_2_s` int(11) DEFAULT 0,
  `Day7_Activity_1` varchar(50) DEFAULT NULL,
  `Day7_Activity_1_s` int(11) DEFAULT 0,
  `Day7_Activity_2` varchar(50) DEFAULT NULL,
  `Day7_Activity_2_s` int(11) DEFAULT 0,
  `Day8_Activity_1` varchar(50) DEFAULT NULL,
  `Day8_Activity_1_s` int(11) DEFAULT 0,
  `Day8_Activity_2` varchar(50) DEFAULT NULL,
  `Day8_Activity_2_s` int(11) DEFAULT 0,
  `Day9_Activity_1` varchar(50) DEFAULT NULL,
  `Day9_Activity_1_s` int(11) DEFAULT 0,
  `Day9_Activity_2` varchar(50) DEFAULT NULL,
  `Day9_Activity_2_s` int(11) DEFAULT 0,
  `Day10_Activity_1` varchar(50) DEFAULT NULL,
  `Day10_Activity_1_s` int(11) DEFAULT 0,
  `Day10_Activity_2` varchar(50) DEFAULT NULL,
  `Day10_Activity_2_s` int(11) DEFAULT 0,
  `Day11_Activity_1` varchar(50) DEFAULT NULL,
  `Day11_Activity_1_s` int(11) DEFAULT 0,
  `Day11_Activity_2` varchar(50) DEFAULT NULL,
  `Day11_Activity_2_s` int(11) DEFAULT 0,
  `Day12_Activity_1` varchar(50) DEFAULT NULL,
  `Day12_Activity_1_s` int(11) DEFAULT 0,
  `Day12_Activity_2` varchar(50) DEFAULT NULL,
  `Day12_Activity_2_s` int(11) DEFAULT 0,
  `Day13_Activity_1` varchar(50) DEFAULT NULL,
  `Day13_Activity_1_s` int(11) DEFAULT 0,
  `Day13_Activity_2` varchar(50) DEFAULT NULL,
  `Day13_Activity_2_s` int(11) DEFAULT 0,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `activity` (3 records)
INSERT INTO `activity` (`email`, `angerscale`, `Day1_Activity_1`, `Day1_Activity_1_s`, `Day1_Activity_2`, `Day1_Activity_2_s`, `Day2_Activity_1`, `Day2_Activity_1_s`, `Day2_Activity_2`, `Day2_Activity_2_s`, `Day3_Activity_1`, `Day3_Activity_1_s`, `Day3_Activity_2`, `Day3_Activity_2_s`, `Day4_Activity_1`, `Day4_Activity_1_s`, `Day4_Activity_2`, `Day4_Activity_2_s`, `Day5_Activity_1`, `Day5_Activity_1_s`, `Day5_Activity_2`, `Day5_Activity_2_s`, `Day6_Activity_1`, `Day6_Activity_1_s`, `Day6_Activity_2`, `Day6_Activity_2_s`, `Day7_Activity_1`, `Day7_Activity_1_s`, `Day7_Activity_2`, `Day7_Activity_2_s`, `Day8_Activity_1`, `Day8_Activity_1_s`, `Day8_Activity_2`, `Day8_Activity_2_s`, `Day9_Activity_1`, `Day9_Activity_1_s`, `Day9_Activity_2`, `Day9_Activity_2_s`, `Day10_Activity_1`, `Day10_Activity_1_s`, `Day10_Activity_2`, `Day10_Activity_2_s`, `Day11_Activity_1`, `Day11_Activity_1_s`, `Day11_Activity_2`, `Day11_Activity_2_s`, `Day12_Activity_1`, `Day12_Activity_1_s`, `Day12_Activity_2`, `Day12_Activity_2_s`, `Day13_Activity_1`, `Day13_Activity_1_s`, `Day13_Activity_2`, `Day13_Activity_2_s`) VALUES
  ('mani@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  ('patient@gmail.com', 'Sever Anger', 'Done', 10, 'Done', 10, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
  ('sp@gmail.com', 'Sever Anger', 'Done', 5, 'Done', 2, 'Done', 1, 'Done', 1, 'Done', 6, 'Done', 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- ----------------------------------------------------------
-- 8. Table Structure for `patient_notifications`
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `category` varchar(50) DEFAULT NULL,
  `action_type` varchar(50) DEFAULT NULL,
  `priority` varchar(20) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_patient_notifications_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table `patient_notifications` (23 records)
INSERT INTO `patient_notifications` (`id`, `email`, `title`, `message`, `category`, `action_type`, `priority`, `is_read`, `created_at`) VALUES
  (1, 'arul@gmail.com', 'Daily Recovery Session Ready', 'Your Day 1 mindfulness exercise is ready. Take 10 minutes to center your thoughts and reduce tension.', 'Therapy', 'start_session', 'normal', 1, '2026-10-20 14:31:30'),
  (2, 'arul@gmail.com', 'Clinical Support Available', 'Dr. Dinesh and your mental health care team are ready if you need guided assistance with anger reduction.', 'Clinician', 'consult_clinic', 'normal', 1, '2026-10-20 14:31:30'),
  (3, 'arul@gmail.com', 'Afternoon Mood Reflection', 'Notice any feelings of irritation? Logging your reflection in the diary helps recalibrate your emotions.', 'Mindfulness', 'write_diary', 'normal', 1, '2026-10-20 14:31:30'),
  (4, 'arul@gmail.com', 'Anger Scale Calibration Ongoing', 'Your baseline assessment establishes your personalized 13-day cognitive therapy roadmap.', 'Milestones', 'view_analytics', 'normal', 1, '2026-10-20 14:31:30'),
  (5, 'arul@gmail.com', 'Clinical Consultation Follow-Up', 'Dr. Dinesh has reviewed your mood chart.', 'Clinician', 'consult_clinic', 'critical', 1, '2026-10-20 14:31:30'),
  (6, 'arul@gmail.com', 'Security Alert: Password Updated', 'Your patient portal password was successfully updated. If you did not make this change, please contact clinic support.', 'Milestones', 'none', 'normal', 1, '2026-10-20 14:31:31'),
  (7, 'testuser@gmail.com', 'Daily Recovery Session Ready', 'Your Day 1 mindfulness exercise is ready. Take 10 minutes to center your thoughts and reduce tension.', 'Therapy', 'start_session', 'normal', 1, '2026-10-20 14:40:19'),
  (8, 'testuser@gmail.com', 'Clinical Support Available', 'Dr. Dinesh and your mental health care team are ready if you need guided assistance with anger reduction.', 'Clinician', 'consult_clinic', 'normal', 1, '2026-10-20 14:40:19'),
  (9, 'testuser@gmail.com', 'Afternoon Mood Reflection', 'Notice any feelings of irritation? Logging your reflection in the diary helps recalibrate your emotions.', 'Mindfulness', 'write_diary', 'normal', 1, '2026-10-20 14:40:19'),
  (10, 'testuser@gmail.com', 'Anger Scale Calibration Ongoing', 'Your baseline assessment establishes your personalized 13-day cognitive therapy roadmap.', 'Milestones', 'view_analytics', 'normal', 1, '2026-10-20 14:40:19'),
  (11, 'testuser@gmail.com', 'Clinical Follow-up Notice', 'Dr. Sarah recommends an in-clinic follow-up session this Thursday.', 'Clinician', 'consult_clinic', 'critical', 1, '2026-10-20 14:40:19'),
  (12, 'arul@gmail.com', 'Security Alert: Password Updated', 'Your patient portal password was successfully updated. If you did not make this change, please contact clinic support.', 'Milestones', 'none', 'normal', 1, '2026-10-20 14:57:40'),
  (13, 'sp@gmail.com', 'Daily Recovery Session Ready', 'Your Day 1 mindfulness exercise is ready. Take 10 minutes to center your thoughts and reduce tension.', 'Therapy', 'start_session', 'normal', 1, '2026-10-20 15:03:20'),
  (14, 'sp@gmail.com', 'Clinical Support Available', 'Dr. Dinesh and your mental health care team are ready if you need guided assistance with anger reduction.', 'Clinician', 'consult_clinic', 'normal', 1, '2026-10-20 15:03:20'),
  (15, 'sp@gmail.com', 'Afternoon Mood Reflection', 'Notice any feelings of irritation? Logging your reflection in the diary helps recalibrate your emotions.', 'Mindfulness', 'write_diary', 'normal', 1, '2026-10-20 15:03:20'),
  (16, 'sp@gmail.com', 'Anger Scale Calibration Ongoing', 'Your baseline assessment establishes your personalized 13-day cognitive therapy roadmap.', 'Milestones', 'view_analytics', 'normal', 1, '2026-10-20 15:03:20'),
  (17, 'sp@gmail.com', 'Clinical Advisory: Clinical Assist Recommended', 'Your recent anger calibration assessment recorded a score of 47/63 (Sever Anger). We strongly advise consulting with your doctor or reaching out to clinic assist.', 'Clinician', 'consult_clinic', 'critical', 1, '2026-10-21 09:10:45'),
  (18, 'gopal@gmail.com', 'Daily Recovery Session Ready', 'Your Day 1 mindfulness exercise is ready. Take 10 minutes to center your thoughts and reduce tension.', 'Therapy', 'start_session', 'normal', 0, '2026-10-21 10:47:25'),
  (19, 'gopal@gmail.com', 'Clinical Support Available', 'Dr. Dinesh and your mental health care team are ready if you need guided assistance with anger reduction.', 'Clinician', 'consult_clinic', 'normal', 0, '2026-10-21 10:47:25'),
  (20, 'gopal@gmail.com', 'Afternoon Mood Reflection', 'Notice any feelings of irritation? Logging your reflection in the diary helps recalibrate your emotions.', 'Mindfulness', 'write_diary', 'normal', 0, '2026-10-21 10:47:25'),
  (21, 'gopal@gmail.com', 'Anger Scale Calibration Ongoing', 'Your baseline assessment establishes your personalized 13-day cognitive therapy roadmap.', 'Milestones', 'view_analytics', 'normal', 1, '2026-10-21 10:47:25'),
  (22, 'sp@gmail.com', 'Clinical Notice from Dr. Dinesh', 'Kindly make appointment for your consultation', 'Clinician', 'consult_clinic', 'critical', 0, '2026-10-21 10:49:06'),
  (23, 'patient@gmail.com', 'Clinical Advisory: Clinical Assist Recommended', 'Your recent anger calibration assessment recorded a score of 38/63 (Sever Anger). We strongly advise consulting with your doctor or reaching out to clinic assist.', 'Clinician', 'consult_clinic', 'critical', 0, '2026-10-21 12:56:52');

SET FOREIGN_KEY_CHECKS = 1;
