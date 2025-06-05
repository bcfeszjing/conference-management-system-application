-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 05, 2025 at 02:52 AM
-- Server version: 10.11.10-MariaDB
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u237859360_cmsa`
--

-- --------------------------------------------------------

--
-- Table structure for table `email_delivery_status`
--

CREATE TABLE `email_delivery_status` (
  `id` int(11) NOT NULL,
  `reference_id` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `attempts` int(11) NOT NULL DEFAULT 0,
  `error_message` text DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_recipients`
--

CREATE TABLE `email_recipients` (
  `id` int(11) NOT NULL,
  `reference_id` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `sent_status` tinyint(4) DEFAULT 0,
  `attempts` int(11) DEFAULT 0,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_sending_log`
--

CREATE TABLE `email_sending_log` (
  `id` int(11) NOT NULL,
  `reference_id` varchar(50) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `status` enum('pending','sent','failed') NOT NULL DEFAULT 'pending',
  `attempted_at` timestamp NULL DEFAULT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_sending_status`
--

CREATE TABLE `email_sending_status` (
  `id` int(11) NOT NULL,
  `reference_id` varchar(50) NOT NULL,
  `total_recipients` int(11) NOT NULL,
  `sent_count` int(11) NOT NULL DEFAULT 0,
  `failed_count` int(11) NOT NULL DEFAULT 0,
  `status` varchar(20) NOT NULL DEFAULT 'in_progress',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `current_batch` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_admins`
--

CREATE TABLE `tbl_admins` (
  `admin_id` int(5) NOT NULL,
  `admin_email` varchar(60) NOT NULL,
  `admin_pass` varchar(40) NOT NULL,
  `conf_id` varchar(10) NOT NULL,
  `conf_email2` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_admins`
--

INSERT INTO `tbl_admins` (`admin_id`, `admin_email`, `admin_pass`, `conf_id`, `conf_email2`) VALUES
(1, 'slumberjer@gmail.com', 'Abc1234@', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_coauthors`
--

CREATE TABLE `tbl_coauthors` (
  `coauthor_id` int(5) NOT NULL,
  `paper_id` varchar(10) NOT NULL,
  `coauthor_email` varchar(100) NOT NULL,
  `coauthor_name` varchar(150) NOT NULL,
  `coauthor_organization` varchar(150) NOT NULL,
  `coauthor_key` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_coauthors`
--

INSERT INTO `tbl_coauthors` (`coauthor_id`, `paper_id`, `coauthor_email`, `coauthor_name`, `coauthor_organization`, `coauthor_key`) VALUES
(1, '6', 'bcfeszjing@gmail.com', 'Tan Luck Phang', 'UUM', ''),
(3, '6', 'poh123@gmail.com', 'Poh Ping Seng', 'USM', '');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_conferences`
--

CREATE TABLE `tbl_conferences` (
  `id` int(3) NOT NULL,
  `conf_id` varchar(10) NOT NULL,
  `conf_name` varchar(100) NOT NULL,
  `admin_email` varchar(50) NOT NULL,
  `conf_status` varchar(10) NOT NULL,
  `conf_type` varchar(50) NOT NULL,
  `conf_doi` varchar(50) NOT NULL,
  `cc_email` varchar(50) NOT NULL,
  `conf_submitdate` date NOT NULL,
  `conf_crsubmitdate` date NOT NULL,
  `conf_date` date NOT NULL,
  `conf_pubst` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_conferences`
--

INSERT INTO `tbl_conferences` (`id`, `conf_id`, `conf_name`, `admin_email`, `conf_status`, `conf_type`, `conf_doi`, `cc_email`, `conf_submitdate`, `conf_crsubmitdate`, `conf_date`, `conf_pubst`) VALUES
(1, 'HFIEJv1', 'Human Factor Ergonomic Journal V1', '', 'Active', 'Journal', 'JF4334-200I', 'slumberjer@gmail.com', '2025-07-20', '2025-07-27', '2025-07-29', 'Published'),
(2, 'CHFIE2025', 'Conference of Human Factor 2025', '', 'Active', 'Conference', '11.0554', 'slumberjer@gmail.com', '2025-08-07', '2025-08-14', '2025-08-16', 'Published');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_fields`
--

CREATE TABLE `tbl_fields` (
  `field_id` int(5) NOT NULL,
  `conf_id` varchar(10) NOT NULL,
  `field_title` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_fields`
--

INSERT INTO `tbl_fields` (`field_id`, `conf_id`, `field_title`) VALUES
(1, 'HFIEJv1', 'Cognitive Ergonomics'),
(2, 'HFIEJv1', 'Physical Ergonomics'),
(3, 'HFIEJv1', 'Organizational Ergonomics'),
(4, 'HFIEJv1', 'Human-Computer Interaction (HCI)'),
(5, 'HFIEJv1', 'Human-Machine Interaction (HMI)'),
(6, 'HFIEJv1', 'Safety Ergonomics'),
(7, 'HFIEJv1', 'Environmental Ergonomics'),
(8, 'HFIEJv1', 'Human Performance'),
(9, 'HFIEJv1', 'Aging and Ergonomics'),
(10, 'HFIEJv1', 'Ergonomics in Healthcare'),
(11, 'HFIEJv1', 'Ergonomics in Transportation'),
(12, 'HFIEJv1', 'Ergonomics in Product Design'),
(13, 'HFIEJv1', 'Virtual Reality and Ergonomics'),
(14, 'HFIEJv1', 'Workplace Ergonomics'),
(15, 'HFIEJv1', 'Ergonomics and Disability'),
(16, 'HFIEJv1', 'Biomechanics'),
(17, 'HFIEJv1', 'Ergonomics in Sports');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_messages`
--

CREATE TABLE `tbl_messages` (
  `message_id` int(8) NOT NULL,
  `user_email` varchar(50) NOT NULL,
  `message_title` varchar(100) NOT NULL,
  `message_content` varchar(500) NOT NULL,
  `message_status` varchar(15) NOT NULL,
  `conf_id` varchar(15) NOT NULL,
  `message_date` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_messages`
--

INSERT INTO `tbl_messages` (`message_id`, `user_email`, `message_title`, `message_content`, `message_status`, `conf_id`, `message_date`) VALUES
(1, 'emily.taylor@email.com', 'Can I apply as reviewer?', 'Is there any criteria to become a reviewer? ', 'Replied', 'HFIEJv1', '2024-08-31 21:34:57.785285'),
(2, 'norlailyhashim@gmail.com', 'Problem in reseting password', 'I have requested to reset my password. I received the email and have clicked the link provided, but the system does not allow me to log in with my new password. Thanks.', 'Replied', 'HFIEJv1', '2024-09-10 09:45:11.533170');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_news`
--

CREATE TABLE `tbl_news` (
  `news_id` int(6) NOT NULL,
  `news_title` varchar(100) NOT NULL,
  `news_content` varchar(2500) NOT NULL,
  `conf_id` varchar(10) NOT NULL,
  `news_date` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_news`
--

INSERT INTO `tbl_news` (`news_id`, `news_title`, `news_content`, `conf_id`, `news_date`) VALUES
(3, 'UPDATE!!!. Call for Submissions: Human Factors and Ergonomics International Journal (HFEIJ)', 'We are pleased to announce that the Human Factors and Ergonomics International Journal (HFEIJ) is now accepting submissions for its upcoming issue. HFEIJ is a leading platform dedicated to advancing the field of human factors, ergonomics, and related disciplines. Our journal seeks original research, review articles, case studies, and technical reports that contribute to the understanding and application of human factors and ergonomics in various domains.\n\nSubmission Guidelines:\nAuthors are invited to submit manuscripts that explore, but are not limited to, the following areas:\n\nCognitive Ergonomics\nPhysical Ergonomics\nHuman-Computer Interaction\nOrganizational Ergonomics\nSafety and Health Ergonomics\nVirtual and Augmented Reality in Ergonomics\nHuman-Machine Interaction\nErgonomics in Healthcare', 'HFIEJv1', '2024-09-03 10:49:00.735239'),
(4, 'Welcome to the Inaugural Edition of HFEIJ Journal', 'We are delighted to announce the launch of the Human Factors and Ergonomics in Innovation Journal (HFEIJ), a premier platform dedicated to advancing the field of ergonomics, human-centered design, and innovation. As we embark on this exciting journey, we aim to foster a collaborative environment where researchers, industry professionals, and academics can share their latest findings and contribute to the evolution of human factors and ergonomics across various sectors.\r\n\r\nOur journal will feature cutting-edge research, case studies, and thought leadership articles that explore emerging trends in ergonomics and human-centered technologies. From workplace ergonomics to human-computer interaction, and from safety management to the development of innovative tools, HFEIJ seeks to highlight diverse perspectives that address real-world challenges and promote healthier, more efficient systems. We invite authors to contribute works that push the boundaries of human-centered research and showcase interdisciplinary approaches.\r\n\r\nThe launch of HFEIJ is a testament to our commitment to fostering an inclusive and forward-thinking community. Our editorial team, comprised of esteemed professionals in the field, will ensure that each submission is meticulously reviewed to uphold the highest standards of academic excellence. We look forward to building a robust network of professionals who are dedicated to enhancing human performance, health, and well-being through ergonomics and innovation. Welcome to the future of human-centered research!', 'HFIEJv1', '2024-09-19 14:13:11.193369');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_papers`
--

CREATE TABLE `tbl_papers` (
  `paper_id` int(5) NOT NULL,
  `paper_title` varchar(250) NOT NULL,
  `paper_abstract` varchar(2000) NOT NULL,
  `paper_keywords` varchar(250) NOT NULL,
  `paper_fields` varchar(600) NOT NULL,
  `paper_name` varchar(40) NOT NULL,
  `user_id` varchar(5) NOT NULL,
  `conf_id` varchar(15) NOT NULL,
  `rev_id` varchar(20) NOT NULL,
  `paper_status` varchar(20) NOT NULL,
  `paper_remark` varchar(800) NOT NULL,
  `payment_id` varchar(20) NOT NULL,
  `paper_ready` varchar(30) NOT NULL,
  `paper_cr_remark` varchar(300) NOT NULL,
  `paper_avgmark` float DEFAULT NULL,
  `paper_pageno` varchar(7) NOT NULL,
  `paper_doi` varchar(50) NOT NULL,
  `paper_date` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_papers`
--

INSERT INTO `tbl_papers` (`paper_id`, `paper_title`, `paper_abstract`, `paper_keywords`, `paper_fields`, `paper_name`, `user_id`, `conf_id`, `rev_id`, `paper_status`, `paper_remark`, `payment_id`, `paper_ready`, `paper_cr_remark`, `paper_avgmark`, `paper_pageno`, `paper_doi`, `paper_date`) VALUES
(1, 'Optimizing Cognitive Load In Human-Computer Interaction: A Framework For Enhancing User Experience In Complex Systems', 'Human-computer interaction (HCI) is a critical area of study in Human Factors and Ergonomics, focusing on the design of systems that optimize user performance and satisfaction. As digital interfaces become increasingly complex, understanding and managing cognitive load has emerged as a key challenge in enhancing user experience (UX). This paper presents a comprehensive framework for optimizing cognitive load in HCI, integrating principles from cognitive ergonomics, usability engineering, and user experience design. The framework is applied to the design and evaluation of a complex software system, demonstrating how cognitive load can be measured, managed, and reduced to improve user performance and satisfaction. The study findings highlight the importance of task simplicity, intuitive navigation, and effective feedback mechanisms in minimizing cognitive overload. Practical recommendations for designers and engineers are provided, offering strategies to balance cognitive demands and optimize user interaction with complex systems. This research contributes to the ongoing discourse in HCI by providing actionable insights for designing user-centered interfaces that enhance performance and reduce the error.', 'Cognitive Load, Human-Computer Interaction (HCI), User Experience (UX)', 'Biomechanics, Cognitive Ergonomics, Human-Computer Interaction (HCI)', 'pap-6-31082024-AVFqR', '6', 'HFIEJv1', '2', 'Under Review', '', '', '', '', 0, '', '', '2024-08-31 16:22:19.979783'),
(2, 'Evaluating The Effectiveness Of Ergonomic Training Programs On Reducing Workplace Injuries In Manufacturing', 'Workplace injuries, particularly those related to repetitive tasks and improper body mechanics, remain a significant concern in the manufacturing industry. This study investigates the effectiveness of ergonomic training programs designed to reduce the incidence of work-related injuries. Over six months, 200 manufacturing workers participated in ergonomic training sessions focused on proper lifting techniques, posture correction, and the use of ergonomic tools. Injury reports and self-assessment surveys were collected before and after the training. The results indicate a substantial decrease in injury rates and an improvement in workers\' awareness of ergonomic practices. The study concludes that continuous ergonomic education is crucial in fostering safer work environments and reducing the physical strain on employees. Practical recommendations for integrating ergonomic training into regular safety protocols are provided.', 'Ergonomic Training, Workplace Injuries, Manufacturing, Injury Prevention, Body Mechanics, Ergonomic Tools, Safety Protocols, Employee Health', 'Ergonomics And Disability, Ergonomics In Healthcare, Ergonomics In Product Design', 'pap-8-31082024-3yv8A', '8', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-08-31 16:23:55.711628'),
(3, 'Human-Centered Design In Autonomous Vehicle Interfaces: Enhancing Trust And Usability', 'The advent of autonomous vehicles (AVs) has introduced new challenges in human-machine interaction, particularly in building user trust and ensuring usability. This paper explores human-centered design principles applied to the development of AV interfaces. By focusing on user needs, behaviors, and expectations, the study aims to create interfaces that enhance trust, usability, and overall user experience. Through a series of user trials and simulations, the research identifies key design elements that influence trust, such as transparency of system operations, feedback mechanisms, and the ability to override automated decisions. The findings highlight the importance of intuitive design and clear communication between the AV and its users. This paper contributes to the field by providing design guidelines that can be adopted by AV developers to improve user acceptance and safety.', 'Human-Centered Design, Autonomous Vehicles, User Trust, Usability, Human-Machine Interaction, Interface Design, User Experience, Design Guidelines', 'Human Performance, Organizational Ergonomics', 'pap-13-31082024-BTpS9', '13', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-08-31 16:25:04.439907'),
(4, 'Ergonomic Risk Assessment Of Agricultural Workers: A Comprehensive Approach To Reducing Occupational Hazards', 'Agricultural workers are often exposed to various ergonomic risks due to the physically demanding nature of their work. This study conducts a comprehensive ergonomic risk assessment to identify and mitigate the most common occupational hazards faced by agricultural workers. Utilizing observational studies, biomechanical analysis, and worker interviews, the research highlights the primary risk factors, including repetitive motions, heavy lifting, and prolonged awkward postures. The study proposes ergonomic interventions such as modified tools, mechanized assistance, and training programs to reduce these risks. The findings suggest that implementing these interventions can significantly lower the incidence of musculoskeletal disorders and improve overall worker health and productivity.', 'Ergonomic Risk Assessment, Agricultural Workers, Occupational Hazards, Musculoskeletal Disorders, Biomechanical Analysis, Ergonomic Interventions, Worker Health, Productivity', 'Physical Ergonomics, Safety Ergonomics', 'pap-21-31082024-VqWgy', '21', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-08-31 16:29:33.740512'),
(5, 'Impact Of Lighting Conditions On Cognitive Performance In Control Room Environments', 'Lighting conditions in control room environments play a crucial role in cognitive performance, particularly in high-stakes situations where attention to detail and quick decision-making are essential. This study examines the impact of different lighting conditions, including intensity, color temperature, and glare, on the cognitive performance of control room operators. Through a series of controlled experiments, the research measures key performance indicators such as reaction time, error rates, and subjective comfort under various lighting scenarios. The results demonstrate that optimal lighting can enhance operator performance, reduce fatigue, and improve overall workplace satisfaction. The paper concludes with recommendations for control room design that prioritize lighting ergonomics to support cognitive function and operator well-being.', 'Lighting Conditions, Cognitive Performance, Control Rooms, Ergonomics, Operator Fatigue, Reaction Time, Workplace Design, Human Factors', 'Environmental Ergonomics, Organizational Ergonomics', 'pap-25-31082024-Tp6hR', '25', 'HFIEJv1', '', 'Received', 'Thank you for your submission. Your paper will be reviewed shortly. Please wait for the review process which will take around 1-2 weeks.', '', '', '', NULL, '', '', '2024-08-31 16:36:01.229320'),
(6, 'The Role Of Ergonomics In Enhancing The Safety Of Construction Workers: A Field Study', 'Construction work is inherently hazardous, with workers frequently exposed to various risks that can lead to serious injuries and long-term health issues. The dynamic and physically demanding nature of construction tasks, such as heavy lifting, awkward postures, repetitive motions, and the use of suboptimal tools, amplifies these risks. This field study aims to explore the critical role of ergonomics in enhancing the safety and well-being of construction workers by systematically addressing these common risk factors. Through comprehensive ergonomic assessments conducted across multiple construction sites, this research identifies key areas where ergonomic interventions can be most effective.\n\n1The study implements a range of ergonomic interventions, including the redesign of tools and equipment to better suit the physical capabilities of workers, modifications to work processes to minimize strain, and targeted safety training programs to raise awareness of ergonomic practices. Additionally, the study considers the impact of environmental factors, such as site layout and accessibility, on worker safety.\n\nThe results demonstrate that these ergonomic interventions not only significantly reduce the incidence of work-related injuries, such as musculoskeletal disorders, but also contribute to improved worker productivity and morale. The findings underscore the importance of integrating ergonomics into standard construction safety protocols as a proactive approach to mitigating risks. Recommendations are made for industry stakeholders to adopt ergonomic principles in the design and management of construction projects, ultimately contributing to the creation of safer and more sustainable work environments.', 'Construction Safety, Ergonomics, Work-Related Injuries, Tool Redesign, Safety Training, Occupational Health, Work Process, Field Study', 'Environmental Ergonomics', 'pap-40-31082024-ccIne', '40', 'HFIEJv1', '3', 'Camera Ready', 'NA', '12', 'cr-6-40-HFIEJv1-bge8B', 'Congrats', 73, '115-25', '10509585.2024.1092066', '2024-08-31 16:39:56.412288'),
(9, 'Evaluating The Impact Of Workspace Design On Cognitive Performance And User Comfort: A Human Factors Approach', 'This study examines the influence of workspace design on cognitive performance and user comfort, focusing on the role of human factors and ergonomics in creating optimal work environments. Through a series of controlled experiments, participants performed cognitive tasks in different workspace configurations, including variations in lighting, chair design, desk height, and noise levels. Results revealed significant correlations between ergonomic improvements and enhanced cognitive function, task efficiency, and overall comfort. These findings highlight the importance of incorporating human-centered design principles into workspace planning to improve productivity and well-being. The research provides valuable insights for ergonomists, office planners, and occupational health professionals aiming to optimize workspaces for both physical and cognitive health.', 'Ergonomics, Human Factors, Workspace Design, Cognitive Performance, User Comfort, Office Environment, Productivity, Occupational Health', 'Cognitive Ergonomics, Ergonomics In Healthcare', 'pap-116-09092024-BPsWr', '116', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-09-09 14:23:25.971758'),
(10, 'ENHANCING INFORMATION SECURITY AWARENESS ON PHISHING AMONG IT STUDENTS: A PILOT TEST CASE STUDY AT POLITEKNIK TUANKU SYED SIRAJUDDIN', 'Students engage with the core operations of university business processes, making them potential targets susceptible to significant cyberattack risks due to their limited experience and knowledge in information security.  Consequently,  IT  students  must  gain  awareness  and  competence  in  information  security  to mitigate  potential  threats  and  attacks,  including  those  related  to  Information  Technology  (IT)  security threats and the loss of valuable information and intellectual assets. This paper aims to assess the Phishing Awareness  Program  implemented  at  the  Department  of  Information  Technology  and  Communication (ITC) in Politeknik Tuanku Syed Sirajuddin (PTSS) and its students\' awareness level.  The significance of this study is focusing on students’ weaknesses and educating them about being cyber victims. Thirty students  were  involved  in  participating  in  this  survey.  They  were  given  a  set  of  questionnaires  and performed pre-test and post-tests. After that, they were given three videos related to phishing and, later, three videos related to the consequences of phishing. Their awareness evaluation was performed after video training had been completed. Even though the score results of the post-test were increased and got positive feedback  from  respondents,  several  respondents  still  got  the  medium-level  score.  Suggestion  for improvement  was  obtained  to  improve  the  current  video  content  and  its  implementation.  This  work contributes to the information security awareness domain, where managers at higher learning institutions can replicate similar processes as proposed in this work in conducting similar training awareness with their students', 'Student Awareness, Cybersecurity, Training Awareness, Phishing Awareness', 'Human-Computer Interaction (HCI)', 'pap-117-10092024-QBilh', '117', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-09-10 09:43:14.169922'),
(11, 'Fundamental Of Biomechanics', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum', 'Biomechanics', 'Biomechanics, Ergonomics And Disability', 'pap-118-10092024-ea7UT', '118', 'HFIEJv1', '', 'Submitted', '', '', '', '', NULL, '', '', '2024-09-10 09:57:30.898513'),
(12, 'Biomechanical Analysis Of Office Workstation Ergonomics: Reducing Musculoskeletal Strain Through Improved Posture And Design', 'This study investigates the relationship between workstation design and biomechanical factors affecting musculoskeletal strain in office environments. Utilizing motion capture and force analysis, the research explores how various ergonomic interventions—such as adjustable chairs, sit-stand desks, and optimized screen positioning—can reduce strain on the neck, shoulders, and lower back. The findings reveal significant improvements in posture and reduction in muscular fatigue with the implementation of proper ergonomic adjustments, highlighting the role of biomechanics in enhancing workplace comfort and productivity. This study provides practical guidelines for ergonomists and designers to mitigate the risks of musculoskeletal disorders through evidence-based workstation design.', 'Biomechanics, Ergonomics, Musculoskeletal Strain, Posture, Office Workstation, Motion Capture, Workplace Design, Human Factors, Occupational Health', 'Biomechanics', 'pap-119-10092024-N1wzw', '119', 'HFIEJv1', '5', 'Pre-Camera Ready', 'Congrats you can proceed with camera ready.', '', 'cr-12-119-HFIEJv1-N3bwu', 'Please reupload', 76, '1-15', '10509585.2024.1092066', '2024-09-10 11:01:35.128093');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payments`
--

CREATE TABLE `tbl_payments` (
  `payment_id` int(5) NOT NULL,
  `paper_id` varchar(5) NOT NULL,
  `user_id` varchar(10) NOT NULL,
  `payment_paid` varchar(10) NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `payment_filename` varchar(20) NOT NULL,
  `payment_status` varchar(20) NOT NULL,
  `payment_remarks` varchar(200) DEFAULT NULL,
  `conf_id` varchar(15) NOT NULL,
  `payment_date` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_payments`
--

INSERT INTO `tbl_payments` (`payment_id`, `paper_id`, `user_id`, `payment_paid`, `payment_method`, `payment_filename`, `payment_status`, `payment_remarks`, `conf_id`, `payment_date`) VALUES
(12, '6', '40', '200', 'Local Order', 'pay-40-yU5kzhxvCE', 'Confirmed', 'okay', 'HFIEJv1', '2025-04-07 02:34:40.000000');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_replies`
--

CREATE TABLE `tbl_replies` (
  `message_id` varchar(10) NOT NULL,
  `author_email` varchar(50) NOT NULL,
  `reply_message` varchar(500) NOT NULL,
  `reply_date` datetime(6) NOT NULL DEFAULT current_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_replies`
--

INSERT INTO `tbl_replies` (`message_id`, `author_email`, `reply_message`, `reply_date`) VALUES
('1', 'slumberjer@gmail.com', 'You need to become our paid member first to be a conf reviewer.', '2024-08-31 21:41:45.247541'),
('1', 'emily.taylor@email.com', 'Thank you for your reply. Sure will request first.', '2024-08-31 21:49:47.731029'),
('1', 'slumberjer@gmail.com', 'We would like to welcome you to our journal. ', '2024-08-31 21:58:40.598384'),
('1', 'emily.taylor@email.com', 'Thanks again for the opportunity,', '2024-08-31 22:58:03.339099'),
('2', 'slumberjer@gmail.com', 'Test', '2024-09-10 11:47:41.270810'),
('1', 'slumberjer@gmail.com', 'No problem', '2025-03-14 12:17:05.000000'),
('1', 'emily.taylor@email.com', 'ok', '2025-03-24 02:32:28.000000'),
('2', 'slumberjer@gmail.com', 'all done thanks', '2025-03-29 13:05:58.000000'),
('2', 'slumberjer@gmail.com', 'test\n', '2025-04-09 05:10:24.000000');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_reviews`
--

CREATE TABLE `tbl_reviews` (
  `review_id` int(5) NOT NULL,
  `rev_id` varchar(5) NOT NULL,
  `paper_id` varchar(5) NOT NULL,
  `user_id` varchar(10) NOT NULL,
  `user_email` varchar(50) NOT NULL,
  `reviewer_remarks` varchar(1000) DEFAULT NULL,
  `review_remarks` varchar(500) DEFAULT NULL,
  `review_confremarks` varchar(1500) DEFAULT NULL,
  `review_totalmarks` varchar(3) NOT NULL,
  `review_status` varchar(20) NOT NULL,
  `rev_release` varchar(5) NOT NULL,
  `review_filename` varchar(20) DEFAULT NULL,
  `conf_id` varchar(15) NOT NULL,
  `review_date` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `rubric_1` int(1) DEFAULT NULL,
  `rubric_1_remark` varchar(500) DEFAULT NULL,
  `rubric_2` int(1) DEFAULT NULL,
  `rubric_2_remark` varchar(500) DEFAULT NULL,
  `rubric_3` int(1) DEFAULT NULL,
  `rubric_3_remark` varchar(500) DEFAULT NULL,
  `rubric_4` int(1) DEFAULT NULL,
  `rubric_4_remark` varchar(500) DEFAULT NULL,
  `rubric_5` int(1) DEFAULT NULL,
  `rubric_5_remark` varchar(500) DEFAULT NULL,
  `rubric_6` int(1) DEFAULT NULL,
  `rubric_6_remark` varchar(500) NOT NULL,
  `rubric_7` int(1) DEFAULT NULL,
  `rubric_7_remark` varchar(500) DEFAULT NULL,
  `rubric_8` int(1) DEFAULT NULL,
  `rubric_8_remark` varchar(500) DEFAULT NULL,
  `rubric_9` int(1) DEFAULT NULL,
  `rubric_9_remark` varchar(500) DEFAULT NULL,
  `rubric_10` int(1) DEFAULT NULL,
  `rubric_10_remark` varchar(500) DEFAULT NULL,
  `rev_bestpaper` varchar(10) NOT NULL,
  `user_release` varchar(5) NOT NULL,
  `rev_status` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_reviews`
--

INSERT INTO `tbl_reviews` (`review_id`, `rev_id`, `paper_id`, `user_id`, `user_email`, `reviewer_remarks`, `review_remarks`, `review_confremarks`, `review_totalmarks`, `review_status`, `rev_release`, `review_filename`, `conf_id`, `review_date`, `rubric_1`, `rubric_1_remark`, `rubric_2`, `rubric_2_remark`, `rubric_3`, `rubric_3_remark`, `rubric_4`, `rubric_4_remark`, `rubric_5`, `rubric_5_remark`, `rubric_6`, `rubric_6_remark`, `rubric_7`, `rubric_7_remark`, `rubric_8`, `rubric_8_remark`, `rubric_9`, `rubric_9_remark`, `rubric_10`, `rubric_10_remark`, `rev_bestpaper`, `user_release`, `rev_status`) VALUES
(1, '39', '6', '12', 'robert.jackson@email.com', 'The paper titled \"Preschooler\'s Game-based Digital Literacy Assessment Application Development\" offers a significant contribution to the field of early childhood education, particularly in addressing the challenge of assessing digital literacy among preschoolers. The study is well-grounded in relevant literature, highlighting the growing importance of digital literacy in the early stages of education and the limitations of traditional assessment methods. The authors effectively propose a game-based assessment as a more engaging and appropriate method for young children, aligning with their developmental needs.', NULL, 'Good', '70', 'Reviewed', 'No', 'rev-1-12345abcde1', 'HFIEJv1', '2024-08-31 17:16:40.160822', 4, 'The title \"Preschooler\'s Game-based Digital Literacy Assessment Application Development\" is clear, concise, and directly reflects the content of the paper. It is suitable for the paper and likely for the conference.\r\n', 4, 'The abstract is well-written, covering the main objectives, methodology, and findings. However, it could be more concise and emphasize the unique contributions of the study.\r\n', 3, 'The introduction is comprehensive, providing a clear background, motivation, and context for the research. It effectively introduces the importance of digital literacy for preschoolers.\r\n', 4, 'The research problem is clearly stated, emphasizing the challenges in assessing preschoolers\' digital literacy and proposing a game-based solution as a viable approach.\r\n', 3, 'The methodology is clear and well described, following a structured Design-Based Research (DBR) approach. However, some details about the iterative process could be expanded for clarity.\r\n', 4, 'The findings are well-presented, with clear discussions on how the game-based assessment was effective. However, the discussion could delve deeper into the implications of these findings.\r\n', 3, 'The figures are generally of good quality, clear, and relevant to the content. However, some figures could benefit from higher resolution and better integration into the text for easier reference.\r\n', 3, 'The topic is highly important, addressing the growing need for digital literacy among preschoolers and offering innovative solutions through game-based assessments.\r\n', 4, 'The paper presents an original approach to assessing digital literacy in preschoolers using game-based methods. The concept is innovative, though similar approaches in other educational areas are noted.\r\n', 3, 'Overall, the paper is well-structured, with a clear focus and contribution to the field of early childhood education and digital literacy. It would benefit from slight refinements in the discussion of findings and methodology details, as well as some improvements to the figures. However, it is a strong submission with significant relevance and originality.\r\n', 'No', 'Yes', ''),
(2, '113', '1', '7', 'susan.miller@email.com', NULL, NULL, NULL, 'NA', 'Assigned', '', NULL, 'HFIEJv1', '2024-09-02 11:18:52.569705', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'No', 'No', ''),
(3, '58', '6', '12', 'robert.jackson@email.com', 'Ok ', NULL, 'Ok', '76', 'Reviewed', 'No', 'rev-3-12345abcde3', 'HFIEJv1', '2024-09-02 20:14:58.519553', 3, 'ok', 4, 'ok', 4, 'Ok', 4, 'OK', 3, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 'No', 'Yes', ''),
(4, '7', '12', '29', 'karen.jones@email.com', 'Ok', NULL, 'Ok', '76', 'Reviewed', 'No', 'rev-4-12345abcde4', 'HFIEJv1', '2024-09-10 11:10:07.475653', 3, 'Ok', 3, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 4, 'Ok', 'No', 'Yes', ''),
(6, '', '1', '1', 'tlp12343324@gmail.com', 'nice', NULL, 'gj', '58', 'Reviewed', '', 'rev-6-12345abcde6', 'HFIEJv1', '2025-03-26 14:00:55.000000', 1, '1', 2, '2', 3, '3', 4, '4', 5, '5', 1, '6', 2, '7', 3, '8', 4, '9', 4, '10', 'Yes', 'Yes', '');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_rubrics`
--

CREATE TABLE `tbl_rubrics` (
  `rubric_id` int(5) NOT NULL,
  `conf_id` varchar(20) NOT NULL,
  `rubric_text` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_rubrics`
--

INSERT INTO `tbl_rubrics` (`rubric_id`, `conf_id`, `rubric_text`) VALUES
(6, 'HFIEJv1', 'Title please check if the title is suitable of this paper?'),
(7, 'HFIEJv1', 'The abstract is it well written?'),
(8, 'HFIEJv1', 'The introduction - is it well written?'),
(9, 'HFIEJv1', 'The research problem - please check if the research problem is stated clearly.'),
(10, 'HFIEJv1', 'The methodology is it clear and well described?'),
(11, 'HFIEJv1', 'The findings are the findings discussed presented and discussed well.'),
(12, 'HFIEJv1', 'Quality of figures please evaluate the quality of figures (if any).'),
(13, 'HFIEJv1', 'The importance of the topic - please comment on the importance of the topic.'),
(14, 'HFIEJv1', 'Originality please comment on the originality of this paper.'),
(18, 'HFIEJv1', 'Overall evaluation please provide a detailed review including justification for your scores.');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_super`
--

CREATE TABLE `tbl_super` (
  `super_id` int(1) NOT NULL,
  `super_email` varchar(50) NOT NULL,
  `super_password` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_super`
--

INSERT INTO `tbl_super` (`super_id`, `super_email`, `super_password`) VALUES
(1, 'slumberjer@gmail.com', 'bec75d2e4e2acf4f4ab038144c0d862505e52d07');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_users`
--

CREATE TABLE `tbl_users` (
  `user_id` int(6) NOT NULL,
  `user_email` varchar(50) NOT NULL,
  `user_password` varchar(40) NOT NULL,
  `user_name` varchar(100) NOT NULL,
  `user_phone` varchar(20) NOT NULL,
  `user_address` varchar(300) NOT NULL,
  `user_title` varchar(30) NOT NULL,
  `user_otp` varchar(5) NOT NULL,
  `user_status` varchar(30) NOT NULL,
  `user_org` varchar(100) NOT NULL,
  `user_country` varchar(50) NOT NULL,
  `user_reset` varchar(40) NOT NULL,
  `user_url` varchar(100) NOT NULL,
  `rev_status` varchar(15) NOT NULL,
  `rev_expert` varchar(300) NOT NULL,
  `rev_cv` varchar(255) DEFAULT NULL,
  `user_datereg` datetime(6) NOT NULL DEFAULT current_timestamp(6),
  `profile_image` varchar(255) DEFAULT NULL,
  `verification_token` varchar(255) DEFAULT NULL,
  `reset_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `tbl_users`
--

INSERT INTO `tbl_users` (`user_id`, `user_email`, `user_password`, `user_name`, `user_phone`, `user_address`, `user_title`, `user_otp`, `user_status`, `user_org`, `user_country`, `user_reset`, `user_url`, `rev_status`, `rev_expert`, `rev_cv`, `user_datereg`, `profile_image`, `verification_token`, `reset_token`) VALUES
(1, 'tlp12343324@gmail.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ahmad Hanis Mohd Shabli', '+60194702493', 'No 597, Jalan Teja 21\r\nTaman Teja Fasa 2', 'Mr', '1', 'Non-Student', 'UUM', 'Malaysia', '1', 'NA', 'Verified', 'Ergonomics and Disability,Physical Ergonomics,Workplace Ergonomics', 'cv-Mr -qs3CNBNXAz', '2024-08-30 17:50:03.942833', NULL, NULL, NULL),
(2, 'john.doe@gmail.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'John Doe', '+60123456789', '123 Main Street\r\nCityville', 'Dr', '1', 'Non-Student', 'UM', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(3, 'jane.smith@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Jane Smith', '+60198765432', '456 Elm Street\r\nSuburbia', 'Prof', '1', 'Student', 'USM', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(4, 'michael.brown@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Michael Brown', '+60192345678', '789 Oak Avenue\r\nMetropolis', 'Assoc. Prof', '1', 'Non-Student', 'UTM', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(6, 'david.wilson@email.com', 'Tlp33241234@', 'David Wilson', '+60193456789', '202 Pine Street\r\nHilltown', 'Mr', '1', 'Non-Student', 'UPM', 'Malaysia', '1', 'NA', 'Unverified', 'Ergonomics in Product Design', 'cv-Mr-e2dbTry51n', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(7, 'susan.miller@email.com', 'Tlp33241234@', 'Susan Miller', '+60194567890', '303 Cedar Avenue\r\nRivercity', 'Dr', '1', 'Non-Student', 'UiTM', 'Malaysia', '1', 'NA', 'Verified', 'Aging and Ergonomics, Biomechanics, Cognitive Ergonomics', 'cv-Mr -qs3CNBNXBz', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(8, 'william.davis@email.com', 'Tlp33241234@', 'William Davis', '+60195678901', '404 Birch Road\r\nForestville', 'Assoc. Prof', '1', 'Student', 'UUM', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(9, 'elizabeth.moore@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Elizabeth Moore', '+60196789012', '505 Spruce Lane\r\nValleyview', 'Mrs', '1', 'Non-Student', 'UNIMAS', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(10, 'james.taylor@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'James Taylor', '+60197890123', '606 Willow Court\r\nMountainpeak', 'Mr', '1', 'Student', 'UTAR', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(11, 'patricia.anderson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Patricia Anderson', '+60198901234', '707 Maple Drive\r\nBrookside', 'Dr', '1', 'Non-Student', 'UCSI', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(12, 'robert.jackson@email.com', 'Tlp33241234@', 'Robert Jackson', '+60199012345', '808 Pine Grove\r\nSunset', 'Assoc. Prof', '1', 'Non-Student', 'UNITEN', 'Malaysia', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Ass-ZdTzIMRlec', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(13, 'linda.martinez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Linda Martinez', '+60190123456', '909 Elm Street\r\nSeaside', 'Mrs', '1', 'Student', 'MMU', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(14, 'charles.thompson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Charles Thompson', '+60191234567', '111 Ash Street\r\nBayside', 'Mr', '1', 'Non-Student', 'SEGi', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(15, 'barbara.white@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Barbara White', '+60192345678', '222 Oak Street\r\nRiverside', 'Dr', '1', 'Non-Student', 'HELP', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(16, 'joseph.harris@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Joseph Harris', '+60193456789', '333 Birch Road\r\nGreentown', 'Assoc. Prof', '1', 'Student', 'Taylor\'s', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(17, 'sarah.clark@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sarah Clark', '+60194567890', '444 Cedar Street\r\nPalmview', 'Mrs', '1', 'Non-Student', 'Sunway', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(18, 'thomas.lewis@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Thomas Lewis', '+60195678901', '555 Pine Avenue\r\nHillcrest', 'Mr', '1', 'Student', 'INTI', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(19, 'nancy.walker@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Nancy Walker', '+60196789012', '666 Spruce Lane\r\nBaytown', 'Dr', '1', 'Non-Student', 'MAHSA', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(20, 'daniel.king@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Daniel King', '+60197890123', '777 Willow Street\r\nEastville', 'Assoc. Prof', '1', 'Non-Student', 'Curtin', 'Malaysia', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Mr -qs3CNBNXCz', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(21, 'laura.hall@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Laura Hall', '+60198901234', '888 Maple Avenue\r\nWestend', 'Mrs', '1', 'Student', 'Monash', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:19:27.702791', NULL, NULL, NULL),
(22, 'alex.johnson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Alex Johnson', '+441234567890', '10 Downing Street\r\nLondon', 'Mr', '1', 'Non-Student', 'Oxford', 'United Kingdom', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(23, 'maria.garcia@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Maria Garcia', '+34678901234', 'Calle Gran Via\r\nMadrid', 'Mrs', '1', 'Student', 'Universidad de Madrid', 'Spain', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(24, 'hiroshi.sato@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Hiroshi Sato', '+81345678901', '1 Chiyoda\r\nTokyo', 'Dr', '1', 'Non-Student', 'University of Tokyo', 'Japan', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(25, 'emily.taylor@email.com', 'Tlp33241234@', 'Emily Taylor', '+61234567890', '200 George Street\r\nSydney', 'Assoc. Prof', '1', 'Non-Student', 'University of Sydney', 'Australia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', 'profile_pic-25', NULL, NULL),
(26, 'li.wei@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Li Wei', '+8613801234567', '5 Dongcheng Road\r\nBeijing', 'Mr', '1', 'Student', 'Peking University', 'China', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(27, 'fatima.ali@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Fatima Ali', '+971501234567', 'Sheikh Zayed Road\r\nDubai', 'Mrs', '1', 'Non-Student', 'American University of Dubai', 'United Arab Emirates', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(28, 'oliver.martin@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Oliver Martin', '+33123456789', 'Avenue des Champs-Élysées\r\nParis', 'Dr', '1', 'Non-Student', 'Sorbonne University', 'France', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(29, 'karen.jones@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Karen Jones', '+16471234567', '5th Avenue\r\nNew York', 'Assoc. Prof', '1', 'Non-Student', 'Columbia University', 'United States', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Mr -qs3CNBNXDz', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(30, 'gustavo.silva@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Gustavo Silva', '+5511987654321', 'Avenida Paulista\r\nSão Paulo', 'Mr', '1', 'Student', 'University of São Paulo', 'Brazil', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(31, 'yara.hassan@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Yara Hassan', '+20212345678', 'Tahrir Square\r\nCairo', 'Mrs', '1', 'Non-Student', 'Cairo University', 'Egypt', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(32, 'max.mustermann@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Max Mustermann', '+4915123456789', 'Unter den Linden\r\nBerlin', 'Dr', '1', 'Non-Student', 'Humboldt University', 'Germany', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(33, 'sophia.rossi@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sophia Rossi', '+393451234567', 'Via Condotti\r\nRome', 'Assoc. Prof', '1', 'Student', 'Sapienza University', 'Italy', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(34, 'michael.lee@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Michael Lee', '+85212345678', 'Nathan Road\r\nHong Kong', 'Mr', '1', 'Non-Student', 'University of Hong Kong', 'Hong Kong', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(35, 'amelie.dubois@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Amelie Dubois', '+33456789012', 'Rue de Rivoli\r\nLyon', 'Mrs', '1', 'Non-Student', 'University of Lyon', 'France', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(36, 'peter.nowak@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Peter Nowak', '+48123456789', 'Krakowskie Przedmie?cie\r\nWarsaw', 'Dr', '1', 'Non-Student', 'University of Warsaw', 'Poland', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(37, 'ana.rodriguez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ana Rodriguez', '+523312345678', 'Paseo de la Reforma\r\nMexico City', 'Assoc. Prof', '1', 'Non-Student', 'National Autonomous University of Mexico', 'Mexico', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(38, 'ivan.ivanov@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ivan Ivanov', '+74951234567', 'Red Square\r\nMoscow', 'Mr', '1', 'Student', 'Moscow State University', 'Russia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(39, 'nina.kim@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Nina Kim', '+82212345678', 'Gangnam\r\nSeoul', 'Mrs', '1', 'Non-Student', 'Seoul National University', 'South Korea', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Mr -qs3CNBNXEz', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(40, 'tlp3324@gmail.com', 'Tlp33241234@', 'Ahmad Khan', '+923012345678', 'Mall Road\r\nLahore', 'Dr', '1', 'Non-Student', 'University of the Punjab', 'Pakistan', '1', 'NA', 'Verified', 'Ergonomics and Disability, Ergonomics in Healthcare, Ergonomics in Product Design', 'cv-Dr-e2f6U7tHEm', '2024-08-30 22:21:07.878598', 'profile_pic-40', NULL, NULL),
(41, 'anna.nilsson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Anna Nilsson', '+46701234567', 'Stortorget\r\nStockholm', 'Assoc. Prof', '1', 'Student', 'Stockholm University', 'Sweden', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:21:07.878598', NULL, NULL, NULL),
(42, 'juan.perez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Juan Perez', '+541123456789', 'Avenida Corrientes\r\nBuenos Aires', 'Mr', '1', 'Non-Student', 'University of Buenos Aires', 'Argentina', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(43, 'katherine.brown@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Katherine Brown', '+16471234568', 'Queen Street\r\nToronto', 'Mrs', '1', 'Student', 'University of Toronto', 'Canada', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(44, 'akio.tanaka@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Akio Tanaka', '+819012345678', 'Shibuya\r\nTokyo', 'Dr', '1', 'Non-Student', 'Waseda University', 'Japan', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(45, 'samantha.evans@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Samantha Evans', '+442071234567', 'Baker Street\r\nLondon', 'Assoc. Prof', '1', 'Non-Student', 'King\'s College London', 'United Kingdom', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(46, 'ricardo.santos@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ricardo Santos', '+5511987654322', 'Rua da Consolação\r\nSão Paulo', 'Mr', '1', 'Student', 'Pontifical Catholic University of São Paulo', 'Brazil', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(47, 'lea.schneider@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Lea Schneider', '+4916212345678', 'Königsallee\r\nDüsseldorf', 'Mrs', '1', 'Non-Student', 'University of Düsseldorf', 'Germany', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(48, 'nikola.jankovic@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Nikola Jankovic', '+381641234567', 'Knez Mihailova\r\nBelgrade', 'Dr', '1', 'Non-Student', 'University of Belgrade', 'Serbia', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Mr -qs3CNBNXFz', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(49, 'lena.nordstrom@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Lena Nordstrom', '+46812345678', 'Drottninggatan\r\nStockholm', 'Assoc. Prof', '1', 'Non-Student', 'KTH Royal Institute of Technology', 'Sweden', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(50, 'ahmad.abdullah@gmail.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ahmad Abdullah', '+966501234567', 'King Fahd Road\r\nRiyadh', 'Mr', '1', 'Student', 'King Saud University', 'Saudi Arabia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(51, 'elna.rodriguez@gmail.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Elena Rodriguez', '+34987654321', 'La Rambla\r\nBarcelona', 'Mrs', '1', 'Non-Student', 'University of Barcelona', 'Spain', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(52, 'tomas.novak@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Tomas Novak', '+420123456789', 'Wenceslas Square\r\nPrague', 'Dr', '1', 'Non-Student', 'Charles University', 'Czech Republic', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(53, 'marie.larsson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Marie Larsson', '+4723456789', 'Karl Johans gate\r\nOslo', 'Assoc. Prof', '1', 'Student', 'University of Oslo', 'Norway', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(54, 'zara.patel@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Zara Patel', '+911234567890', 'Connaught Place\r\nNew Delhi', 'Mrs', '1', 'Non-Student', 'University of Delhi', 'India', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(55, 'david.mwangi@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'David Mwangi', '+254701234567', 'Kenyatta Avenue\r\nNairobi', 'Mr', '1', 'Non-Student', 'University of Nairobi', 'Kenya', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(57, 'ali.mohamed@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ali Mohamed', '+20123456789', 'Zamalek\r\nCairo', 'Assoc. Prof', '1', 'Non-Student', 'The American University in Cairo', 'Egypt', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(58, 'lucas.martinez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Lucas Martinez', '+34123456789', 'Gran Via\r\nMadrid', 'Mr', '1', 'Student', 'Autonomous University of Madrid', 'Spain', '1', 'NA', 'Verified', 'Physical Ergonomics, Safety Ergonomics, Virtual Reality and Ergonomics', 'cv-Mr -qs3CNBNXGz', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(59, 'fiona.murphy@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Fiona Murphy', '+35312345678', 'O\'Connell Street\r\nDublin', 'Mrs', '1', 'Non-Student', 'Trinity College Dublin', 'Ireland', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(60, 'andre.silva@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Andre Silva', '+351123456789', 'Avenida da Liberdade\r\nLisbon', 'Dr', '1', 'Non-Student', 'University of Lisbon', 'Portugal', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(61, 'sara.nielsen@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sara Nielsen', '+4523456789', 'Strøget\r\nCopenhagen', 'Assoc. Prof', '1', 'Non-Student', 'University of Copenhagen', 'Denmark', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:22:40.007774', NULL, NULL, NULL),
(62, 'miguel.diaz@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Miguel Diaz', '+34912345678', 'Calle Mayor\r\nMadrid', 'Mr', '1', 'Non-Student', 'Complutense University of Madrid', 'Spain', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(63, 'laura.wilson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Laura Wilson', '+16171234567', 'Michigan Avenue\r\nChicago', 'Mrs', '1', 'Student', 'University of Chicago', 'United States', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(64, 'chen.wang@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Chen Wang', '+8613812345678', 'Nanjing Road\r\nShanghai', 'Dr', '1', 'Non-Student', 'Fudan University', 'China', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(65, 'isabella.bianchi@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Isabella Bianchi', '+390612345678', 'Via del Corso\r\nRome', 'Assoc. Prof', '1', 'Non-Student', 'University of Rome', 'Italy', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(66, 'mohamed.ali@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Mohamed Ali', '+971561234567', 'Al Maktoum Road\r\nDubai', 'Mr', '1', 'Student', 'University of Dubai', 'United Arab Emirates', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(67, 'elena.ivanova@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Elena Ivanova', '+749512345678', 'Arbat Street\r\nMoscow', 'Mrs', '1', 'Non-Student', 'Moscow State University', 'Russia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(68, 'william.moore@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'William Moore', '+61234567890', 'Collins Street\r\nMelbourne', 'Dr', '1', 'Non-Student', 'University of Melbourne', 'Australia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(69, 'anna.svensson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Anna Svensson', '+46701234567', 'Götgatan\r\nStockholm', 'Assoc. Prof', '1', 'Student', 'Stockholm University', 'Sweden', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(70, 'carlos.martinez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Carlos Martinez', '+525512345678', 'Avenida Insurgentes\r\nMexico City', 'Mr', '1', 'Non-Student', 'National Autonomous University of Mexico', 'Mexico', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(71, 'yasmin.ahmed@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Yasmin Ahmed', '+20212345679', 'Garden City\r\nCairo', 'Mrs', '1', 'Non-Student', 'Cairo University', 'Egypt', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(72, 'olivier.dubois@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Olivier Dubois', '+33123456789', 'Boulevard Saint-Germain\r\nParis', 'Dr', '1', 'Non-Student', 'Sorbonne University', 'France', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(73, 'mia.jensen@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Mia Jensen', '+45451234567', 'Strandvejen\r\nCopenhagen', 'Assoc. Prof', '1', 'Student', 'University of Copenhagen', 'Denmark', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(74, 'leonardo.santos@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Leonardo Santos', '+5511987654323', 'Avenida Paulista\r\nSão Paulo', 'Mr', '1', 'Non-Student', 'University of São Paulo', 'Brazil', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(75, 'sophie.muller@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sophie Muller', '+496912345678', 'Zeil\r\nFrankfurt', 'Mrs', '1', 'Non-Student', 'Goethe University Frankfurt', 'Germany', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(76, 'peter.johnson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Peter Johnson', '+442071234568', 'Oxford Street\r\nLondon', 'Dr', '1', 'Non-Student', 'University College London', 'United Kingdom', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(77, 'jin.lee@gmail.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Jin Lee', '+821012345678', 'Gangnam\r\nSeoul', 'Assoc. Prof', '1', 'Student', 'Seoul National University', 'South Korea', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(78, 'emanuel.rodrigues@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Emanuel Rodrigues', '+351912345678', 'Avenida da Liberdade\r\nLisbon', 'Mr', '1', 'Non-Student', 'University of Lisbon', 'Portugal', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(79, 'marta.novakova@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Marta Novakova', '+420212345678', 'Václavské nám?stí\r\nPrague', 'Mrs', '1', 'Non-Student', 'Charles University', 'Czech Republic', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(80, 'liam.brown@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Liam Brown', '+61234567891', 'George Street\r\nSydney', 'Dr', '1', 'Non-Student', 'University of Sydney', 'Australia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(81, 'natalia.ramos@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Natalia Ramos', '+56212345678', 'Avenida Providencia\r\nSantiago', 'Assoc. Prof', '1', 'Non-Student', 'Pontifical Catholic University of Chile', 'Chile', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(82, 'khaled.hassan@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Khaled Hassan', '+20123456780', 'Tahrir Square\r\nCairo', 'Mr', '1', 'Student', 'Ain Shams University', 'Egypt', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(83, 'lucy.wilson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Lucy Wilson', '+441234567890', 'Royal Mile\r\nEdinburgh', 'Mrs', '1', 'Non-Student', 'University of Edinburgh', 'United Kingdom', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(84, 'nikita.volkov@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Nikita Volkov', '+78121234567', 'Nevsky Prospekt\r\nSaint Petersburg', 'Dr', '1', 'Non-Student', 'Saint Petersburg State University', 'Russia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(85, 'freya.nielsen@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Freya Nielsen', '+4589123456', 'Nyhavn\r\nCopenhagen', 'Assoc. Prof', '1', 'Student', 'Technical University of Denmark', 'Denmark', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(86, 'omar.al-farsi@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Omar Al-Farsi', '+96890123456', 'Al Khuwair\r\nMuscat', 'Mr', '1', 'Non-Student', 'Sultan Qaboos University', 'Oman', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(87, 'victoria.robinson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Victoria Robinson', '+61234567892', 'Queen Street\r\nBrisbane', 'Mrs', '1', 'Non-Student', 'University of Queensland', 'Australia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(88, 'jan.kowalski@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Jan Kowalski', '+48123456789', 'Krakowskie Przedmie?cie\r\nWarsaw', 'Dr', '1', 'Non-Student', 'University of Warsaw', 'Poland', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(89, 'sofia.martinez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sofia Martinez', '+571123456789', 'Carrera 7\r\nBogotá', 'Assoc. Prof', '1', 'Student', 'University of the Andes', 'Colombia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(90, 'ali.reza@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ali Reza', '+982112345678', 'Valiasr Street\r\nTehran', 'Mr', '1', 'Non-Student', 'University of Tehran', 'Iran', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(91, 'olga.smirnova@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Olga Smirnova', '+749512345679', 'Leninsky Prospekt\r\nMoscow', 'Mrs', '1', 'Non-Student', 'Higher School of Economics', 'Russia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(92, 'yusuf.demir@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Yusuf Demir', '+905301234567', 'Istiklal Avenue\r\nIstanbul', 'Dr', '1', 'Non-Student', 'Istanbul University', 'Turkey', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:24:57.836778', NULL, NULL, NULL),
(93, 'natalie.moreno@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Natalie Moreno', '+571234567890', 'Calle 100\r\nBogotá', 'Mrs', '1', 'Non-Student', 'National University of Colombia', 'Colombia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(94, 'mohammad.aziz@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Mohammad Aziz', '+9647901234567', 'Karrada\r\nBaghdad', 'Mr', '1', 'Non-Student', 'University of Baghdad', 'Iraq', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(95, 'amelia.dupont@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Amelia Dupont', '+334912345678', 'Cours Mirabeau\r\nAix-en-Provence', 'Mrs', '1', 'Student', 'Aix-Marseille University', 'France', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(96, 'noah.kim@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Noah Kim', '+82221234567', 'Itaewon\r\nSeoul', 'Dr', '1', 'Non-Student', 'Korea University', 'South Korea', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(97, 'aline.moura@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Aline Moura', '+558712345678', 'Avenida Boa Viagem\r\nRecife', 'Assoc. Prof', '1', 'Non-Student', 'Federal University of Pernambuco', 'Brazil', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(98, 'hassan.al-amri@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Hassan Al-Amri', '+966531234567', 'King Abdullah Road\r\nJeddah', 'Mr', '1', 'Student', 'King Abdulaziz University', 'Saudi Arabia', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(99, 'grace.nguyen@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Grace Nguyen', '+84812345678', 'Nguyen Hue Boulevard\r\nHo Chi Minh City', 'Mrs', '1', 'Non-Student', 'Vietnam National University', 'Vietnam', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(100, 'peter.hansson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Peter Hansson', '+46731234567', 'Östermalm\r\nStockholm', 'Dr', '1', 'Non-Student', 'Karolinska Institute', 'Sweden', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(101, 'rita.fernandez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Rita Fernandez', '+521234567890', 'Calle 50\r\nMonterrey', 'Assoc. Prof', '1', 'Non-Student', 'Tecnológico de Monterrey', 'Mexico', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(102, 'joseph.owen@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Joseph Owen', '+442012345678', 'Abbey Road\r\nLondon', 'Mr', '1', 'Non-Student', 'Imperial College London', 'United Kingdom', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(103, 'laura.richter@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Laura Richter', '+493012345678', 'Kurfürstendamm\r\nBerlin', 'Mrs', '1', 'Student', 'Freie Universität Berlin', 'Germany', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(104, 'ibrahim.mohamed@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ibrahim Mohamed', '+201011234567', 'Zamalek\r\nCairo', 'Dr', '1', 'Non-Student', 'Ain Shams University', 'Egypt', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(105, 'emilia.varga@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Emilia Varga', '+36301234567', 'Andrássy Avenue\r\nBudapest', 'Assoc. Prof', '1', 'Non-Student', 'Eötvös Loránd University', 'Hungary', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(106, 'javier.rodriguez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Javier Rodriguez', '+56201234567', 'Alameda\r\nSantiago', 'Mr', '1', 'Student', 'University of Chile', 'Chile', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(107, 'ayesha.khan@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Ayesha Khan', '+923012345678', 'Clifton\r\nKarachi', 'Mrs', '1', 'Non-Student', 'University of Karachi', 'Pakistan', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(108, 'sven.olsson@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Sven Olsson', '+46812345678', 'Södermalm\r\nStockholm', 'Dr', '1', 'Non-Student', 'Stockholm University', 'Sweden', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(109, 'hannah.murphy@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Hannah Murphy', '+35312345679', 'Temple Bar\r\nDublin', 'Assoc. Prof', '1', 'Non-Student', 'University College Dublin', 'Ireland', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(110, 'kai.wu@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Kai Wu', '+8613812345679', 'Wangfujing\r\nBeijing', 'Mr', '1', 'Student', 'Tsinghua University', 'China', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(111, 'luisa.martinez@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Luisa Martinez', '+34123456789', 'Paseo del Prado\r\nMadrid', 'Mrs', '1', 'Non-Student', 'Complutense University of Madrid', 'Spain', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(112, 'emily.clark@email.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Emily Clark', '+16171234568', 'Fifth Avenue\r\nNew York', 'Dr', '1', 'Non-Student', 'Columbia University', 'United States', '1', 'NA', 'NA', 'NA', 'NA', '2024-08-30 22:27:06.488278', NULL, NULL, NULL),
(113, 'johnam@email.com', '2ca24ac081c517a7aa774d74293c3260950c3290', 'John Nam', '0193334432', 'Unesco, Malaysia', 'Prof', '1', 'Non-Student', 'UNESCO', 'Malaysia', '0', 'NA', 'Verified', 'Aging And Ergonomics,Biomechanics,Cognitive Ergonomics', 'NA', '2024-09-01 19:42:21.805801', NULL, NULL, NULL),
(114, 'limtang@email.com', 'c9be7cd43aebe594bfe761579060df0a240b8c4e', 'Lim Tang ', '033224566', 'UN, Nigeria', 'Mr', '1', 'Non-Student', 'UN', 'Nigeria', '1', 'NA', 'Verified', 'Environmental Ergonomics,Ergonomics And Disability,Ergonomics In Healthcare', 'cv-Lim-BA9CTPGC6D', '2024-09-01 19:51:19.201868', NULL, NULL, NULL),
(115, 'vepex93336@ndiety.com', '5fa1e54f81cd74b80b665eea3cb9bd6ced084133', 'Vivek Ramasamy', '0112233555466', 'Vex Pro, California', 'Prof', '1', 'Non-Student', 'Vex Pro', 'United States of America', '1', 'NA', 'Verified', 'Virtual Reality And Ergonomics,Workplace Ergonomics', 'cv-Viv-c9eGUU4Nmh', '2024-09-01 19:54:03.543449', NULL, NULL, NULL),
(116, 'femovaw495@esterace.com', 'c27121bb0633356b86ec1914790d60dc10a0e4bb', 'Jukka Virtanen', '+358401234567', 'Katajatie 5\r\n00230 Helsinki\r\nFinland', 'Dr', '1', 'Non-Student', 'Femova Inc', 'Finland', '92641', 'NA', 'NA', 'Safety Ergonomics,Virtual Reality and Ergonomics,Workplace Ergonomics', 'NA', '2024-09-09 13:44:27.155291', NULL, NULL, NULL),
(117, 'norlailyhashim@gmail.com', 'Tlp33241234@', 'Nor Laily Hashim', '+60195110666', 'SOC, UUM,', 'Assoc Prof', '1', 'Non-Student', 'UUM', 'Malaysia', '1', 'NA', 'Unverified', 'Human-Computer Interaction (HCI)', 'cv-Ass-tOgKa8vxXx', '2024-09-10 09:15:40.728099', NULL, NULL, NULL),
(118, 'amran@uum.edu.my', '862bffd3a14f343f266de6ae527e300e23798289', 'Amran Ahmad', '0194764694', 'School Of Computing\r\nUniversiti Utara Malaysia\r\n06010 UUM Sintok\r\nKedah', 'Dr', '1', 'Non-Student', 'UUM', 'Malaysia', '1', 'NA', 'NA', 'NA', 'NA', '2024-09-10 09:31:11.992886', NULL, NULL, NULL),
(119, 'poxohe3327@konetas.com', 'Tlp33241234@', 'Elina Mäkelä', '+358 50 987 6544', 'Saaristokatu 15 90100 Oulu\rFinland', 'Mr', '1', 'Non-Student', 'PoXo Inc', 'Finland', '1', 'NA', 'Unverified', 'Biomechanics, Cognitive Ergonomics, Human-Computer Interaction (HCI)', 'cv-Mr-2KiZcX2m5D', '2024-09-10 10:46:58.254725', NULL, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `email_delivery_status`
--
ALTER TABLE `email_delivery_status`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reference_id` (`reference_id`,`email`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `email_recipients`
--
ALTER TABLE `email_recipients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reference_sent` (`reference_id`,`sent_status`);

--
-- Indexes for table `email_sending_log`
--
ALTER TABLE `email_sending_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reference_id` (`reference_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `email_sending_status`
--
ALTER TABLE `email_sending_status`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_admins`
--
ALTER TABLE `tbl_admins`
  ADD PRIMARY KEY (`admin_id`);

--
-- Indexes for table `tbl_coauthors`
--
ALTER TABLE `tbl_coauthors`
  ADD PRIMARY KEY (`coauthor_id`);

--
-- Indexes for table `tbl_conferences`
--
ALTER TABLE `tbl_conferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `conf_id` (`conf_id`);

--
-- Indexes for table `tbl_fields`
--
ALTER TABLE `tbl_fields`
  ADD PRIMARY KEY (`field_id`);

--
-- Indexes for table `tbl_messages`
--
ALTER TABLE `tbl_messages`
  ADD PRIMARY KEY (`message_id`);

--
-- Indexes for table `tbl_news`
--
ALTER TABLE `tbl_news`
  ADD PRIMARY KEY (`news_id`);

--
-- Indexes for table `tbl_papers`
--
ALTER TABLE `tbl_papers`
  ADD PRIMARY KEY (`paper_id`);

--
-- Indexes for table `tbl_payments`
--
ALTER TABLE `tbl_payments`
  ADD PRIMARY KEY (`payment_id`);

--
-- Indexes for table `tbl_reviews`
--
ALTER TABLE `tbl_reviews`
  ADD PRIMARY KEY (`review_id`);

--
-- Indexes for table `tbl_rubrics`
--
ALTER TABLE `tbl_rubrics`
  ADD PRIMARY KEY (`rubric_id`);

--
-- Indexes for table `tbl_super`
--
ALTER TABLE `tbl_super`
  ADD PRIMARY KEY (`super_id`);

--
-- Indexes for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `email_delivery_status`
--
ALTER TABLE `email_delivery_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_recipients`
--
ALTER TABLE `email_recipients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_sending_log`
--
ALTER TABLE `email_sending_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_sending_status`
--
ALTER TABLE `email_sending_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_admins`
--
ALTER TABLE `tbl_admins`
  MODIFY `admin_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_coauthors`
--
ALTER TABLE `tbl_coauthors`
  MODIFY `coauthor_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `tbl_conferences`
--
ALTER TABLE `tbl_conferences`
  MODIFY `id` int(3) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `tbl_fields`
--
ALTER TABLE `tbl_fields`
  MODIFY `field_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `tbl_messages`
--
ALTER TABLE `tbl_messages`
  MODIFY `message_id` int(8) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `tbl_news`
--
ALTER TABLE `tbl_news`
  MODIFY `news_id` int(6) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=67;

--
-- AUTO_INCREMENT for table `tbl_papers`
--
ALTER TABLE `tbl_papers`
  MODIFY `paper_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `tbl_payments`
--
ALTER TABLE `tbl_payments`
  MODIFY `payment_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `tbl_reviews`
--
ALTER TABLE `tbl_reviews`
  MODIFY `review_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `tbl_rubrics`
--
ALTER TABLE `tbl_rubrics`
  MODIFY `rubric_id` int(5) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `tbl_super`
--
ALTER TABLE `tbl_super`
  MODIFY `super_id` int(1) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tbl_users`
--
ALTER TABLE `tbl_users`
  MODIFY `user_id` int(6) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=143;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
