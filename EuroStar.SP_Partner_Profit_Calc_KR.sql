/****** Object:  StoredProcedure [dbo].[SP_Partner_Profit_Calc_KR]    Script Date: 2019/1/3 下午 04:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Kevin #1684
-- Create date: 2018/12
-- Description:	CTE 傭金
-- {#1684} {日期:2019/1/3} {Kevin} [佣金] KR代理佣金daily job重寫 + C/MC/Rollback機制
-- =============================================
ALTER PROCEDURE [dbo].[SP_Partner_Profit_Calc_KR]

AS
BEGIN

SET NOCOUNT ON;
DECLARE @startDate1 DATE;
DECLARE @start DATETIME;
SET @startDate1 = GETUTCDATE();
SELECT @start = DATEADD(DAY, 0, @startDate1);
SET @start = DATEADD(HOUR, -9, @Start);
DECLARE @end DATETIME;
SET @end = @start + '23:59:59.998'

Declare @Level int = 1
 --會員層級 

  
;WITH tempTree
AS
(SELECT
		@Level Level
	   ,m.m_idx
	   ,m.m_id
	   ,TMP.SP_ProfitType AS SP_ProfitType
	   ,TMP.CA_ProfitType AS CA_ProfitType
	   ,TMP.MG_ProfitType AS MG_ProfitType
	   ,TMP.GG_ProfitType AS GG_ProfitType
		--%
	   ,TMP.SP_SharePoint AS SP_SharePoint
	   ,TMP.SP_SharePoint_Parlay AS SP_SharePoint_Parlay
	   ,TMP.CA_SharePoint AS CA_SharePoint
	   ,TMP.MG_SharePoint AS MG_SharePoint
	   ,TMP.GG_SharePoint AS GG_SharePoint
		--
	   ,CAST(TMP.SP_SharePoint AS FLOAT) AS SP_COMMISSION
	   ,CAST(TMP.SP_SharePoint_Parlay AS FLOAT) AS SP_Parlay_COMMISSION
	   ,CAST(TMP.CA_SharePoint AS FLOAT) AS CA_COMMISSION
	   ,CAST(TMP.MG_SharePoint AS FLOAT) AS MG_COMMISSION
	   ,CAST(TMP.GG_SharePoint AS FLOAT) AS GG_COMMISSION
		--
	   ,m.ref_m_Idx


	FROM T_Member m
	JOIN T_MemberProfit TMP
		ON m.ref_m_Idx = TMP.m_Idx


	UNION ALL

	SELECT
		TreeNode.Level + 1
	   ,TM.m_Idx
	   ,TM.m_Id
	   ,TreeNode.SP_ProfitType AS SP_ProfitType
	   ,TreeNode.CA_ProfitType AS CA_ProfitType
	   ,TreeNode.MG_ProfitType AS MG_ProfitType
	   ,TreeNode.GG_ProfitType AS GG_ProfitType
		-- %
	   ,TreeNode.SP_SharePoint AS SP_SharePoint
	   ,TreeNode.SP_SharePoint_Parlay AS SP_SharePoint_Parlay
	   ,TreeNode.CA_SharePoint AS CA_SharePoint
	   ,TreeNode.MG_SharePoint AS MG_SharePoint
	   ,TreeNode.GG_SharePoint AS GG_SharePoint
		--
	   ,CASE
			WHEN TreeNode.Level > 1 THEN TreeNode.SP_COMMISSION
			ELSE CAST((TreeNode.SP_COMMISSION - TMP.SP_SharePoint) AS FLOAT)
		END
		AS SP_COMMISSION
	   ,CASE
			WHEN TreeNode.Level > 1 THEN TreeNode.SP_Parlay_COMMISSION
			ELSE CAST((TreeNode.SP_Parlay_COMMISSION - TMP.SP_SharePoint_Parlay) AS FLOAT)
		END
		AS SP_Parlay_COMMISSION
	   ,CASE
			WHEN TreeNode.Level > 1 THEN TreeNode.CA_COMMISSION
			ELSE CAST((TreeNode.CA_COMMISSION - TMP.CA_SharePoint) AS FLOAT)
		END
		AS CA_COMMISSION
	   ,CASE
			WHEN TreeNode.Level > 1 THEN TreeNode.MG_COMMISSION
			ELSE CAST((TreeNode.MG_SharePoint - TMP.MG_SharePoint) AS FLOAT)
		END
		AS MG_COMMISSION
	   ,CASE
			WHEN TreeNode.Level > 1 THEN TreeNode.GG_COMMISSION
			ELSE CAST((TreeNode.GG_SharePoint - TMP.GG_SharePoint) AS FLOAT)
		END
		AS GG_COMMISSION
	   ,TreeNode.ref_m_Idx

	FROM T_Member TM
	JOIN tempTree TreeNode
		ON TM.ref_m_Idx = TreeNode.m_Idx
	JOIN T_MemberProfit TMP
		ON TMP.m_Idx = TM.ref_m_Idx)
--INSERT INTO T_Partner_Profit_Test(partnerIdx,fromPartnerIdx,pSIteIdx,profitPrice,profitCD,title,[status],regDate,regEmpNo,etc,refProfitSeq,refBetJoinDate,refBetResultDate)
INSERT INTO T_Partner_Profit(partnerIdx,fromPartnerIdx,pSIteIdx,profitPrice,profitCD,title,[status],regDate,regEmpNo,etc,refProfitSeq,refBetJoinDate,refBetResultDate)
SELECT
	tt.ref_m_Idx AS partnerIdx
   ,tt.m_Idx AS fromPartnerIdx
   ,'1' AS pSIteIdx
   ,CAST(
	CASE
		WHEN TGB.gameType = 'sp' AND
			tt.SP_ProfitType = 3 THEN ((TGB.betPrice - TGB.betrsltPrice) * (tt.SP_COMMISSION) / 100)
		WHEN TGB.gameType = 'gg' AND
			tt.GG_ProfitType = 3 THEN ((TGB.betPrice - TGB.betrsltPrice) * (tt.GG_COMMISSION) / 100)
		WHEN TGB.gameType = 'ca' AND
			tt.CA_ProfitType = 3 THEN ((TGB.betPrice - TGB.betrsltPrice) * (tt.CA_COMMISSION) / 100)
		WHEN TGB.gameType = 'mg' AND
			tt.MG_ProfitType = 3 THEN ((TGB.betPrice - TGB.betrsltPrice) * (tt.MG_COMMISSION) / 100)

		WHEN TGB.gameType = 'sp' AND
			TGB.masterSeq > 1 AND
			tt.SP_ProfitType = 4 THEN ((TGB.betPrice) * (tt.SP_Parlay_COMMISSION) / 100)
		WHEN TGB.gameType = 'sp' AND
			TGB.masterSeq = 1 AND
			tt.SP_ProfitType = 4 THEN ((TGB.betPrice) * (tt.SP_COMMISSION) / 100)
		WHEN TGB.gameType = 'gg' AND
			tt.GG_ProfitType = 4 THEN ((TGB.betPrice) * (tt.GG_COMMISSION) / 100)
		WHEN TGB.gameType = 'ca' AND
			tt.CA_ProfitType = 4 THEN ((TGB.betPrice) * (tt.CA_COMMISSION) / 100)
		WHEN TGB.gameType = 'mg' AND
			tt.MG_ProfitType = 4 THEN ((TGB.betPrice) * (tt.MG_COMMISSION) / 100)

	END AS BIGINT
	) AS profitPrice
   ,CAST(
	CASE
		WHEN TGB.gameType = 'sp' THEN CASE
				WHEN tt.SP_ProfitType = 3 THEN '11'
				WHEN tt.SP_ProfitType = 4 THEN '12'
				ELSE CAST(tt.SP_ProfitType AS NVARCHAR)
			END
		WHEN TGB.gameType = 'gg' THEN CASE
				WHEN tt.GG_ProfitType = 3 THEN '11'
				WHEN tt.GG_ProfitType = 4 THEN '12'
				ELSE CAST(tt.GG_ProfitType AS NVARCHAR)
			END
		WHEN TGB.gameType = 'ca' THEN CASE
				WHEN tt.CA_ProfitType = 3 THEN '11'
				WHEN tt.CA_ProfitType = 4 THEN '12'
				ELSE CAST(tt.CA_ProfitType AS NVARCHAR)
			END
		WHEN TGB.gameType = 'mg' THEN CASE
				WHEN tt.MG_ProfitType = 3 THEN '11'
				WHEN tt.MG_ProfitType = 4 THEN '12'
				ELSE CAST(tt.GG_ProfitType AS NVARCHAR)
			END

	END AS NVARCHAR
	) AS profitCD
   ,CAST(
	CASE
		WHEN TGB.gameType = 'sp' THEN CASE
				WHEN tt.SP_ProfitType = '3' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
				WHEN tt.SP_ProfitType = '4' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
			END
		WHEN TGB.gameType = 'gg' THEN CASE
				WHEN tt.GG_ProfitType = '3' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
				WHEN tt.GG_ProfitType = '4' THEN  CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
			END
		WHEN TGB.gameType = 'ca' THEN CASE
				WHEN tt.CA_ProfitType = '3' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
				WHEN tt.CA_ProfitType = '4' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
			END
		WHEN TGB.gameType = 'mg' THEN CASE
				WHEN tt.GG_ProfitType = '3' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_W/L수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END
				WHEN tt.GG_ProfitType = '4' THEN CASE
						WHEN (Level - 1) = 0 THEN CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add '
						ELSE CAST(tt.m_Idx AS NVARCHAR(10)) + N' KR_Bet수익 Add - ' + CAST(Level - 1 AS NVARCHAR) + 'STEP'
					END

			END
	END AS NVARCHAR
	) AS title
   ,'D' AS [status]
   ,GETUTCDATE() AS regDate
   ,CAST(
	CASE
		WHEN TGB.gameType = 'sp' THEN '1'
		WHEN TGB.gameType = 'gg' THEN '3'
		WHEN TGB.gameType = 'ca' THEN '2'
		WHEN TGB.gameType = 'mg' THEN '4'
	END AS NVARCHAR
	) AS regEmpNo
   ,CAST(
	CASE
		WHEN TGB.gameType = 'sp' AND
			TGB.masterSeq > 1 AND
			tt.SP_ProfitType = 4 THEN (tt.SP_Parlay_COMMISSION)
		WHEN TGB.gameType = 'sp' THEN (tt.SP_COMMISSION)
		WHEN TGB.gameType = 'gg' THEN (tt.GG_COMMISSION)
		WHEN TGB.gameType = 'ca' THEN (tt.CA_COMMISSION)
		WHEN TGB.gameType = 'mg' THEN (tt.MG_COMMISSION)
	END AS FLOAT
	) AS etc
   ,TGB.betGrpSeq AS betGrpSeq
   ,TGB.betJoinDate AS betJoinDate
   ,TGB.betResultDate AS betResultDate

--, '----' As TT_Split
--, tt.* 
--,'----' As MP_Split
--, mp.* 

FROM tempTree tt
JOIN T_MemberProfit mp
	ON tt.m_Idx = mp.m_Idx
-- Bet Result List
JOIN T_GrpBetInfo TGB
	ON mp.m_Idx = TGB.m_idx
		AND TGB.betResultDate BETWEEN @Start AND @End
		AND grpBetRslt = 'EM'		
ORDER BY TGB.betGrpSeq, title ASC

-- Max Recursive Level.13
OPTION (MAXRECURSION 13);


--	C / MC  Thea提供
UPDATE T_Partner_Profit
SET pSIteIdx = profitPrice
   ,profitPrice = 0
   ,status = 'Discard'
WHERE pIdx IN (SELECT
    a.pIdx
	FROM (SELECT
      ROW_NUMBER() OVER (PARTITION BY refProfitSeq, title ORDER BY p.pIdx DESC) AS Sort
       ,m.m_id
       ,p.*
    FROM T_Partner_Profit p WITH (NOLOCK)
    LEFT JOIN T_Member m WITH (NOLOCK)
      ON p.partnerIdx = m.m_Idx
    WHERE refProfitSeq IN (SELECT
        p.refProfitSeq
      FROM T_Partner_Profit p WITH (NOLOCK)
      WHERE p.profitCD IN (1, 2, 4, 11, 12)
      AND profitPrice != 0
      AND regDate > '20181201'
      GROUP BY p.title
          ,p.refProfitSeq
      HAVING COUNT(refProfitSeq) > 1)  --order by refProfitSeq, title, pIdx desc
  ) a
  WHERE a.Sort != 1)


END