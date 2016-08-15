DROP TABLE CUSTOM.CUSTOM_EARLY_WARNING_BEHAVIOR;

CREATE TABLE CUSTOM.CUSTOM_EARLY_WARNING_BEHAVIOR (
STUDENT_NUMBER INT,
STUDENTID INT,
STUDENTKEY INT,
SYSTEMSTUDENTID VARCHAR(25),
TERMKEY INT,
COUNT_OSS INT,
DAYS_OF_OSS INT,
NUM_OF_INCIDENTS INT,
NUM_OF_REFERRAL INT);

CREATE INDEX EW_BEHAVIOR ON CUSTOM.CUSTOM_EARLY_WARNING_BEHAVIOR (STUDENT_NUMBER,TERMKEY);

INSERT INTO CUSTOM.CUSTOM_EARLY_WARNING_BEHAVIOR (STUDENT_NUMBER,STUDENTID,STUDENTKEY,SYSTEMSTUDENTID,TERMKEY,COUNT_OSS,DAYS_OF_OSS,NUM_OF_INCIDENTS,NUM_OF_REFERRAL)
SELECT
S.STUDENT_NUMBER AS STUDENT_NUMBER,
S.ID AS STUDENTID,
DS.STUDENTKEY,
DS.SYSTEMSTUDENTID,
COALESCE(CAST(CAST(T.ID AS VARCHAR) + CAST(E.SCHOOLID AS VARCHAR) AS INT),-1) AS TERMKEY, --CREATE TERMKEY BY CONCATENATING TERMID AND A.SCHOOLID AND CASTING AS INT
SUM(CASE WHEN DL.PENALTYNAME IS NOT NULL THEN 1 ELSE 0 END) COUNT_OSS,
SUM(CASE WHEN DL.NUMDAYS IS NULL THEN 0 ELSE DL.NUMDAYS END) DAYS_OF_OSS,
SUM(CASE WHEN I.COUNT_INCIDENTS IS NULL THEN 0 ELSE I.COUNT_INCIDENTS END) NUM_OF_INCIDENTS,
SUM(CASE WHEN I.COUNT_REFERRAL IS NULL THEN 0 ELSE I.COUNT_REFERRAL END) NUM_OF_REFERRAL
FROM POWERSCHOOL.POWERSCHOOL_STUDENTS S
JOIN (SELECT SCHOOLID, ID AS STUDENTID, ENTRYDATE, EXITDATE, GRADE_LEVEL FROM POWERSCHOOL.POWERSCHOOL_STUDENTS S
		UNION
	  SELECT SCHOOLID, STUDENTID, ENTRYDATE, EXITDATE, GRADE_LEVEL FROM POWERSCHOOL.POWERSCHOOL_REENROLLMENTS R) E ON E.STUDENTID = S.ID
JOIN [custom].[custom_StudentBridge] SB ON SB.STUDENT_NUMBER = S.STUDENT_NUMBER
JOIN DW.DW_DIMSTUDENT DS ON DS.SYSTEMSTUDENTID = SB.SYSTEMSTUDENTID
JOIN POWERSCHOOL.POWERSCHOOL_CALENDAR_DAY CD ON CD.SCHOOLID = E.SCHOOLID AND CD.DATE_VALUE BETWEEN E.ENTRYDATE AND E.EXITDATE
LEFT JOIN [powerschool].[powerschool_TERMS] T ON CD.DATE_VALUE BETWEEN T.FIRSTDAY AND T.LASTDAY AND T.SCHOOLID = E.SCHOOLID
LEFT JOIN (SELECT
			I.STUDENTSCHOOLID,
			PENALTYNAME,
			P.STARTDATE,
			P.ENDDATE,
			P.NUMDAYS
			FROM CUSTOM_DLINCIDENTS_RAW I
			JOIN CUSTOM_DLPENALTIES_RAW P ON P.INCIDENTID = I.INCIDENTID
			WHERE PENALTYNAME = 'OSS') DL ON DL.STUDENTSCHOOLID = S.STUDENT_NUMBER AND DL.STARTDATE = CD.DATE_VALUE
LEFT JOIN (SELECT 
			STUDENTSCHOOLID,
			ISSUETS,
			COUNT(*) COUNT_INCIDENTS,
			SUM(CASE WHEN ISREFERRAL = 'True' THEN 1 ELSE 0 END) COUNT_REFERRAL
			FROM CUSTOM_DLINCIDENTS_RAW I
			WHERE CATEGORY NOT LIKE 'Attendance%'
			GROUP BY STUDENTSCHOOLID, ISSUETS) I ON I.STUDENTSCHOOLID = S.STUDENT_NUMBER AND I.ISSUETS = CD.DATE_VALUE
WHERE CD.INSESSION = 1
AND T.YEARID >= 25 --Only include incidents and referrals from the 15-16 school year on since that was when DeansList was implemented
AND S.SCHOOLID != 999999
GROUP BY S.STUDENT_NUMBER,
		 T.ID,
		 S.ID,
		 DS.STUDENTKEY,
		 DS.SYSTEMSTUDENTID,
		 E.SCHOOLID
