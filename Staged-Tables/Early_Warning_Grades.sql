DROP TABLE CUSTOM.CUSTOM_EARLY_WARNING_GRADES;

CREATE TABLE CUSTOM.CUSTOM_EARLY_WARNING_GRADES (
STUDENT_NUMBER INT,
STUDENTID INT,
STUDENTKEY INT,
SYSTEMSTUDENTID VARCHAR(25),
TERMKEY INT,
NUM_Ds_AND_Fs INT);

CREATE INDEX EW_GRADES ON CUSTOM.CUSTOM_EARLY_WARNING_GRADES (STUDENT_NUMBER,TERMKEY);

INSERT INTO CUSTOM.CUSTOM_EARLY_WARNING_GRADES (STUDENT_NUMBER,STUDENTID,STUDENTKEY,SYSTEMSTUDENTID,TERMKEY,NUM_Ds_AND_Fs)
SELECT
POWERSCHOOL_STUDENTS.STUDENT_NUMBER AS STUDENT_NUMBER,
POWERSCHOOL_STUDENTS.ID AS STUDENTID,
[STUDENT].[STUDENTKEY],
[STUDENT].SYSTEMSTUDENTID AS SYSTEMSTUDENTID,
COALESCE(CAST(CAST(GT.ID AS VARCHAR) + [ENROLLMENT].SYSTEMSCHOOLID AS INT),-1) AS 'TERMKEY',
SUM(CASE WHEN ([GRADE].GRADENAME LIKE 'D%' OR [GRADE].GRADENAME = 'F') THEN 1 ELSE 0 END) '# Ds AND Fs'
FROM [GRADES].[DW_FACTGRADESSCORES] [GRADES SCORES]
  INNER JOIN [DW].[DW_DIMCLASS] [CLASS] ON ([GRADES SCORES].[CLASSKEY] = [CLASS].[CLASSKEY])
  INNER JOIN [GRADES].[DW_DIMGRADE] [GRADE] ON ([GRADES SCORES].[GRADEKEY] = [GRADE].[GRADEKEY])
  INNER JOIN [DW].[DW_DIMSTUDENT] [STUDENT] ON ([GRADES SCORES].[STUDENTKEY] = [STUDENT].[STUDENTKEY])
  INNER JOIN [DW].[DW_DIMCLASSENROLLMENT] [CLASS ENROLLMENT] ON ([GRADES SCORES].[CLASSENROLLMENTKEY] = [CLASS ENROLLMENT].[CLASSENROLLMENTKEY])
  INNER JOIN [DW].[DW_DIMENROLLMENT] [ENROLLMENT] ON ([GRADES SCORES].[ENROLLMENTKEY] = [ENROLLMENT].[ENROLLMENTKEY])
  INNER JOIN [GRADES].[DW_DIMGRADEPERIOD] [GRADE PERIOD] ON ([GRADES SCORES].[GRADEPERIODKEY] = [GRADE PERIOD].[GRADEPERIODKEY])
  INNER JOIN [DW].[DW_DIMTERM] [TERM] ON ([GRADES SCORES].[TERMKEY] = [TERM].[TERMKEY])
  INNER JOIN [CUSTOM].[CUSTOM_STUDENTBRIDGE] [CUSTOM_STUDENTBRIDGE] ON ([STUDENT].[SYSTEMSTUDENTID] = [CUSTOM_STUDENTBRIDGE].[SYSTEMSTUDENTID])
  INNER JOIN [POWERSCHOOL].[POWERSCHOOL_STUDENTS] [POWERSCHOOL_STUDENTS] ON ([CUSTOM_STUDENTBRIDGE].[STUDENT_NUMBER] = [POWERSCHOOL_STUDENTS].[STUDENT_NUMBER])
  LEFT JOIN CUSTOM.CUSTOM_TERM_CONVERSIONS GT ON GT.SCHOOLID =  CAST([ENROLLMENT].SYSTEMSCHOOLID AS INT) AND GT.FINALGRADENAME = GRADEPERIODABBREVIATION AND RIGHT(ENROLLMENT.SCHOOLYEAR4DIGIT,2)+9 = GT.YEARID
  WHERE [CLASS ENROLLMENT].CLASSENROLLMENTSTATUS IN ('Completed','Currently Enrolled')
    AND [GRADE].GRADESCORETYPE = 'Overall'
    AND (([ENROLLMENT].GRADELEVEL IN ('9th','10th','11th','12th') 
    AND [CLASS].SUBJECTAREA IN ('ELA', 'HIST', 'MATH', 'SCIENCE','FLANG')) -- STUDENT IN GRADE 9 OR HIGHER AND HS CORE CREDIT TYPES
    OR ([ENROLLMENT].GRADELEVEL IN ('PK3','PK4','K','1st','2nd','3rd','4th','5th','6th','7th','8th')
		AND (
		   [CLASS].COURSENAME LIKE '%Math'
		OR [CLASS].COURSENAME LIKE '%Reading' 
		OR [CLASS].COURSENAME LIKE '%Science' 
		OR [CLASS].COURSENAME LIKE '%Social Studies' 
		OR [CLASS].COURSENAME LIKE '%Science and Social Studies' 
		OR [CLASS].COURSENAME LIKE '%Science & Social Studies' 
		OR [CLASS].COURSENAME LIKE 'Algebra I'
		OR [CLASS].COURSENAME LIKE '%English'
		OR [CLASS].COURSENAME LIKE '%General Knowledge (Sci and SS)'
		OR [CLASS].COURSENAME LIKE '%World Studies'
		OR [CLASS].COURSENAME LIKE '%Language Arts'
		OR [CLASS].COURSENAME LIKE '%Literacy'
		OR [CLASS].COURSENAME LIKE '%Writing')))
		--add literacy for K-4 only
GROUP BY [POWERSCHOOL_STUDENTS].STUDENT_NUMBER
		,[STUDENT].SYSTEMSTUDENTID
		,[TERM].SCHOOLYEAR4DIGIT
		,[GT].ID
		,[POWERSCHOOL_STUDENTS].ID
		,[STUDENT].STUDENTKEY
		,[ENROLLMENT].SYSTEMSCHOOLID
--ORDER BY POWERSCHOOL_STUDENTS.STUDENT_NUMBER,TERMKEY
;
