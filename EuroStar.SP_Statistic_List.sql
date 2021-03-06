USE [EuroStarABC]
GO
/****** Object:  StoredProcedure [dbo].[SP_Statistic_List]    Script Date: 2018/11/29 下午 05:35:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Kevin
-- Create date: 2018/11/28
-- Description:	需求 版本翻寫
/*
exec SP_Statistic_List @P_startDate= '2018-10-13',@P_endDate ='2018-11-28', @P_searchMode='D', @P_pageIndex = 1, @P_pageSize = 100 ,@P_timeZone = 9 ,@P_groupCategory=NULL ,@P_productCategoryID=''
exec SP_Statistic_List @P_startDate= '2018-10-29',@P_endDate ='2018-11-30', @P_searchMode='GD', @P_pageIndex = 1, @P_pageSize = 100 ,@P_timeZone = 9 ,@P_groupCategory=NULL ,@P_productCategoryID='ALL'
exec SP_Statistic_List @P_startDate= '2018-11-05',@P_endDate ='2018-11-06', @P_searchMode='GW', @P_pageIndex = 1, @P_pageSize = 100 ,@P_timeZone = 9 ,@P_groupCategory=NULL ,@P_productCategoryID='ALL'

exec SP_Statistic_List @P_startDate= '2018-11-05',@P_endDate ='2018-11-06', @P_searchMode='W', @P_pageIndex = 1, @P_pageSize = 100 ,@P_timeZone = 9 ,@P_groupCategory=NULL ,@P_productCategoryID=''

SELECT sum(betprice)  FROM T_GrpBetInfo  with (NOLOCK)
WHERE grpBetRslt = 'EM' and
betJoinDate between '20181104 15:00:00' and '20181106 15:00:00'


*/
-- =============================================
ALTER PROCEDURE [dbo].[SP_Statistic_List]
	@P_startDate	varchar(10) = ''
,	@P_endDate	varchar(10) = ''
,	@P_searchMode	varchar(2) = 'D' --//mode (D:daily, W:weekly, M: monthly, Y:yearly, G:gameType)
,   @P_timeZone int = 9
,   @P_groupCategory nvarchar(1)=''  -- 2018-07-02 add  MKT=>Reports=>category    value=Y，(N or '')  
,   @P_pageIndex int
,   @P_pageSize int
,	@P_productCategoryID nvarchar(10) = ''  -- ALL, sp, ca, gg, mg
AS
BEGIN	
	SET NOCOUNT ON;
																				------------------
																				--	Kevin		--
																				--	2018/11/28	--
																				--	版本翻寫	--
																				------------------
	DECLARE @P_category Nvarchar(10)   --EX:SBK、Graph
	DECLARE @P_gametype Nvarchar(2)   --EX:sp、gg  (T_GrpBetInfo.gametype)

	Declare @P_Start	DateTime, @P_End	DateTime

	Set @P_Start = DATEADD(HOUR,-@P_timeZone, Cast( @P_startDate As datetime))
	Set @P_End	= DATEADD(DAY,1,DATEADD(HOUR,-@P_timeZone, Cast( @P_endDate As datetime))) -- 結束日再加一天



			-- 把搜尋區間的資料全都抓出來

Select 

		Cast(c.DateInfo As date)									DateInfo
		,Cast(ISNULL(c.AFFWDPrice,0) As BIGINT)						AFFWDPrice
		,Cast(ISNULL(c.AFFDPPrice,0) As BIGINT)						AFFDPPrice
		,Cast(ISNULL(g.Turnover,0) As BIGINT)						BetPrice
		,Cast(ISNULL(g.BetCount,0)  As BIGINT)						BetCount
		,Cast(ISNULL(c.BonusPrice,0) As BIGINT)						BonusPrice
		,Cast(ISNULL(c.DepositPrice,0) As BIGINT)					DepositPrice
		,Cast(ISNULL(c.WithDrawPrice,0) As BIGINT)					WithDrawPrice
		,Cast(ISNULL(g.GGR,0)  As BIGINT)							GGR
		,Cast(ISNULL(c.HOLD,0) As BIGINT)							HOLD    -- 已改前端計算此欄位
		,Cast(ISNULL(g.GGR - c.BonusPrice,0) As BIGINT)				NGR
		,Cast(ISNULL(g.GGR + g.Turnover,0) As BIGINT)				ReFundPrice
		,Cast(ISNULL(c.ActiveMemberCnt,0) 	As INT)					ActiveMemberCnt
		,Cast(ISNULL(c.NewDepositCnt,0)  As INT)					NewDepositCnt
		,Cast(ISNULL(c.NewMemberCnt,0) As INT)						NewMemberCnt
		,Cast(ISNULL(c.RetensionCnt,0) As INT)						RetensionCnt
		,Cast(ISNULL(c.LastActiveMemberCnt,0) As INT)				LastActiveMemberCnt
		,Cast(t.CD_NM As Nvarchar) 									gameType
		,TotalCount = COUNT(1) OVER()



 FROM (



			Select  
					Cast(b.DateInfo As date)							DateInfo,
					Cast( 0	 As BIGINT)									AFFWDPrice,
					Cast(Sum( ISNULL(b.Affiliate,0)) As BIGINT)			AFFDPPrice,
					--Cast(SUM( ISNULL(b.Turnover,0)) As BIGINT)			BetPrice,
					--Cast(SUM( ISNULL(b.BetCount,0)) As BIGINT)			BetCount,
					Cast(Sum(ISNULL(b.Bonus,0)) As BIGINT)				BonusPrice,
					Cast(Sum(ISNULL(b.Deposit,0) ) As BIGINT)			DepositPrice,
					Cast(Sum(ISNULL(b.Withdraw,0) ) As BIGINT)			WithDrawPrice,
					--Cast(Sum(ISNULL(b.GGR,0 )) As BIGINT)				GGR,
					Cast( 0	 As BIGINT)									HOLD,       -- 已改前端計算此欄位
					--Cast(Sum( ISNULL(b.GGR,0) - ISNULL(b.Bonus,0)) As BIGINT)	 NGR,
					--Cast(Sum(ISNULL(b.GGR,0) + ISNULL(b.Turnover,0)) As BIGINT)  ReFundPrice,
					Cast(Sum( ISNULL(b.UAP,0) )	As INT)					ActiveMemberCnt,
					Cast(Sum( ISNULL(b.[1st time Deposit],0)) As INT)	NewDepositCnt,
					Cast(Sum( ISNULL(b.[New Registration],0)) As INT)	NewMemberCnt,
					Cast(0 As INT)										RetensionCnt,
					Cast(0 As INT)										LastActiveMemberCnt
					--isnull(t.CM_CD,'')									GameType,
					--Sum(b.Deposit) Deposit,			
					--Sum(b.Withdraw) 'Withdraw',			
					--SUM(b.Turnover) 'Turnover',					
					--Sum(b.Bonus) Bonus,			
					--Sum(b.Affiliate) Affiliate,			
			From
			(
				Select 
				a.Dateinfo
				,a.[1st time Deposit] as [1st time Deposit]
				,a.Affiliate as Affiliate
				,a.Bonus as Bonus
				,a.Deposit as Deposit
				,a.[New Registration] as [New Registration]
				,a.UAP as UAP
				,a.Withdraw as Withdraw
				,a.GGR as GGR
				,a.Turnover as Turnover
				From(

				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,m_reg_DT)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,m_reg_DT)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,m_reg_DT)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,m_reg_DT)), 0))as date) 
				End	Dateinfo,		
				count(m_Idx) as 'New Registration'  , 
				0 UAP,
				0 '1st time Deposit',
				0 Withdraw,
				0 Turnover,
				0 GGR,
				0 Bonus,
				0 Affiliate,
				0 Deposit
				FROM T_Member WITH(nolock)
				WHERE m_reg_DT between @P_Start and @P_End AND m_Deleted = '0' AND m_Status = '1'
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,m_reg_DT))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,m_reg_DT))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,m_reg_DT))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,m_reg_DT))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,m_reg_DT) AS DATE)
				)

				Union ALL

				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,regDT)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,regDT)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,regDT)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,regDT)), 0))as date) 
				End	Dateinfo,	
				 0 'New Registration', 
				 COUNT(DISTINCT(userIdx)) UAP , 
				 0 '1st time Deposit', 
				 0 Withdraw, 
				 0 Turnover, 
				 0 GGR, 
				 0 Bonus, 
				 0 Affiliate,
				 0 Deposit
				FROM ActionLog_FE WITH(nolock)
				WHERE regDT  between @P_Start and @P_End 
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,regDT))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,regDT))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,regDT))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,regDT))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,regDT) AS DATE)
				)
	
				Union ALL

				(
				SELECT  
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,m_FirstDeposit_DT)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT)), 0))as date) 
				End	Dateinfo,	
				0 'New Registration', 
				0 UAP, 
				count(m_Idx) as '1st time Deposit' , 
				0 Withdraw, 
				0 Turnover, 
				0 GGR, 
				0 Bonus, 
				0 Affiliate,
				0 Deposit
				FROM T_Member with (NOLOCK)
				WHERE m_FirstDeposit_DT between @P_Start and @P_End AND m_Deleted = '0' AND m_Status = '1'
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,m_FirstDeposit_DT))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,m_FirstDeposit_DT) AS DATE)
				)

				Union ALL
	
				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,regDate)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,regDate)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,regDate)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,regDate)), 0))as date) 
				End	Dateinfo,		
				0 'New Registration',
				0 UAP,
				0 '1st time Deposit',
				Cast(sum(Price) As BIGINT )as Withdraw ,
				0 Turnover,
				0 GGR,
				0 Bonus,
				0 Affiliate,
				0 Deposit
				FROM T_PaymentInfo  with (NOLOCK)
				WHERE p_status = 'PM' and status = 2 and regDate between @P_Start and @P_End
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,regDate))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,regDate) AS DATE)
				) 

				Union ALL

				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,modDate)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,modDate)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,modDate)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,modDate)), 0))as date) 
				End	Dateinfo,	
				0 'New Registration',
				0 UAP,
				0 '1st time Deposit',
				0 Withdraw ,
				0 Turnover,
				0 GGR,
				Cast(sum(depositPrice) As BIGINT ) Bonus,
				0 Affiliate,
				0 Deposit
				FROM T_DepositInfo  with (NOLOCK)
				WHERE p_status = 'RM' and status = 2 and modDate between @P_Start and @P_End
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,modDate))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,modDate) AS DATE)
				) 

				Union ALL

				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,regDate)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,regDate)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,regDate)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,regDate)), 0))as date) 
				End	Dateinfo,
				0 'New Registration',
				0 UAP,
				0 '1st time Deposit',
				0 Withdraw ,
				0 Turnover,
				0 GGR,
				0 Bonus,
				Cast(sum(profitPrice) As BIGINT )Affiliate,
				0 Deposit
				FROM T_Partner_Profit with (NOLOCK) 
				WHERE profitCD in (11,12,1,2,4) and	regDate between @P_Start and @P_End
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,regDate))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,regDate))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,regDate) AS DATE)
				) 	
		
				Union ALL

				(
				SELECT 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,modDate)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,modDate)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,modDate)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,modDate)), 0))as date) 
				End	Dateinfo,
				--CAST(MIN(Dateadd(hour,@P_timeZone,modDate)) as date)  Dateinfo,	
				--CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,modDate)), -1))as date) Dateinfo,
				0 'New Registration',
				0 UAP,
				0 '1st time Deposit',
				0 Withdraw ,
				0 Turnover,
				0 GGR,
				0 Bonus,
				0 Affiliate,
				Cast(sum(depositPrice) As BIGINT )as Deposit
				FROM [T_DepositInfo]  with (NOLOCK)
				WHERE p_status = 'PM' and status = 2 and modDate between @P_Start and @P_End
				Group by 
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,modDate))
					--When @P_searchMode = 'W' or @P_searchMode = 'GW'Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,modDate))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,modDate))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,modDate) AS DATE)
				)

				--Union ALL

				--(
				--SELECT	
				--Case
				--	When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,betJoinDate)) as date)  
				--	When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,betJoinDate)), -1))as date) 
				--	When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,betJoinDate)), -1))as date) 
				--	When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,betJoinDate)), -1))as date) 
				--End	Dateinfo,		
				--0 'New Registration',
				--0 UAP,
				--0 '1st time Deposit',
				--0 Withdraw ,
				--0 Turnover,
				--0 GGR,
				--0 Bonus,
				--0 Affiliate,
				--0 Deposit
				--FROM T_GrpBetInfo with (NOLOCK)
				--WHERE grpBetRslt = 'EM' and	betJoinDate between @P_Start and @P_End 
				--Group by 
				--Case
				--	When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,betJoinDate))
				--	When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,betJoinDate))
				--	When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,betJoinDate))
				--	When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,betJoinDate))
				--End
				----group by CAST(Dateadd(hour,@P_timeZone,betJoinDate) AS DATE)
				--) 

		
				)a 


			) b


			Group By b.DateInfo
			--Order By b.DateInfo DESC 
			
			
		) c	
							LEFT JOIN 

				
				(
				
				SELECT	
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then CAST(MIN(Dateadd(hour,@P_timeZone,betJoinDate)) as date)  
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then CAST(MIN(DATEADD(wk, DATEDIFF(wk,0,Dateadd(hour,@P_timeZone,betJoinDate)), -1))as date) 
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then CAST(MIN(DATEADD(MONTH, DATEDIFF(MONTH,0,Dateadd(hour,@P_timeZone,betJoinDate)), 0))as date) 
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then CAST(MIN(DATEADD(YEAR, DATEDIFF(YEAR,0,Dateadd(hour,@P_timeZone,betJoinDate)), 0))as date) 
				End	Dateinfo,		
				Cast(sum(betPrice) As BIGINT ) Turnover,
				Cast((sum(betrsltPrice-betPrice))*-1 As BIGINT ) GGR ,
				count(betGrpSeq) as BetCount ,
				Case
					When @P_searchMode in ('D','W','M','Y') Then ''
					When @P_searchMode in ('GD', 'GW','GM','GY')  Then gameType
				END gameType
				FROM T_GrpBetInfo with (NOLOCK)
				WHERE grpBetRslt = 'EM' and	betJoinDate between @P_Start and @P_End  AND gameType like '%'+(case when @P_productCategoryID='ALL' then '' else @P_productCategoryID end )+'%'
				Group by 
				Case
					When @P_searchMode in ('D','W','M','Y') Then ''
					When @P_searchMode in ('GD', 'GW','GM','GY')  Then gameType
				END,
				Case
					When @P_searchMode = 'D' or @P_searchMode = 'GD' Then datepart(day,Dateadd(hour,@P_timeZone,betJoinDate))
					When @P_searchMode = 'W' or @P_searchMode = 'GW' Then DATEPART(WEEK,Dateadd(hour,@P_timeZone,betJoinDate))
					When @P_searchMode = 'M' or @P_searchMode = 'GM' Then DATEPART(MONTH,Dateadd(hour,@P_timeZone,betJoinDate))
					When @P_searchMode = 'Y' or @P_searchMode = 'GY' Then DATEPART(YEAR,Dateadd(hour,@P_timeZone,betJoinDate))
				End
				--group by CAST(Dateadd(hour,@P_timeZone,betJoinDate) AS DATE)
				) g on g.Dateinfo = c.dateinfo
	
			LEFT JOIN T_CODE T with (NOLOCK) on t.CD_CD = g.gameType and t.CM_CD = 'ProductCategory'
			where g.gameType like '%'+(case when @P_productCategoryID='ALL' then '' else @P_productCategoryID end )+'%'
			Order by c.DateInfo , t.CD_NM Desc
			OFFSET (@P_pageIndex - 1) * @P_pageSize  ROWS  
			FETCH NEXT @P_pageSize ROWS ONLY;


			
			
			
			--OFFSET (@P_pageIndex - 1) * @P_pageSize  ROWS  
			--FETCH NEXT @P_pageSize ROWS ONLY;














    /*
	CREATE TABLE #rtnTbl_Money (
		DateInfo	date NOT NULL,
		GameType Nvarchar(10),--2018-07-02 add column
		DepositPrice	BIGINT DEFAULT 0,
		BetPrice		BIGINT DEFAULT 0,
		BetCount		BIGINT DEFAULT 0,
		ReFundPrice		BIGINT DEFAULT 0,
		BonusPrice		BIGINT DEFAULT 0,
		WithDrawPrice	BIgINT DEFAULT 0,
		AFFDPPrice	BIGINT DEFAULT 0,
		AFFWDPrice	BIGINT DEFAULT 0,
		GGR			BIGINT DEFAULT 0,
		NGR			BIGINT DEFAULT 0,
		HOLD		BIGINT DEFAULT 0
	);

	CREATE TABLE #rtnTbl_Member (
		DateInfo	date NOT NULL,
		NewMemberCnt		INT DEFAULT 0,
		NewDepositCnt		INT DEFAULT 0,
		ActiveMemberCnt		INT DEFAULT 0,
		RetensionCnt		INT	DEFAULT 0,
		LastActiveMemberCnt	INT	DEFAULT 0
	);

	INSERT INTO #rtnTbl_Money 
	EXEC SP_StatisticMoney_List @P_startDate=@P_startDate, @P_endDate =@P_endDate , @P_searchMode = @P_searchMode ,@P_timeZone = @P_timeZone ,@P_groupCategory=@P_groupCategory, @P_productCategoryID = @P_productCategoryID;

	INSERT INTO #rtnTbl_Member
	EXEC SP_StatisticMember_List @P_startDate=@P_startDate, @P_endDate =@P_endDate , @P_searchMode = @P_searchMode ,@P_timeZone = @P_timeZone;

	WITH T AS 
	(
		SELECT B.DateInfo, A.GameType, ISNULL(A.AFFDPPrice,0) AFFDPPrice, ISNULL(A.AFFWDPrice,0) AFFWDPrice
		, ISNULL(A.BetPrice,0) BetPrice, ISNULL(A.BetCount,0) BetCount, ISNULL(A.BonusPrice,0) BonusPrice
		, ISNULL(A.DepositPrice,0) DepositPrice , ISNULL(A.WithDrawPrice,0) WithDrawPrice
		,ISNULL(A.GGR,0) GGR, ISNULL(A.HOLD,0) HOLD, ISNULL(A.NGR,0) NGR, ISNULL(A.ReFundPrice,0) ReFundPrice
		, ISNULL(B.ActiveMemberCnt, 0) ActiveMemberCnt
		, ISNULL(B.NewDepositCnt, 0) NewDepositCnt, ISNULL(B.NewMemberCnt, 0) NewMemberCnt
		, ISNULL(B.RetensionCnt,0) RetensionCnt
		, ISNULL(B.LastActiveMemberCnt,0) LastActiveMemberCnt 
		FROM #rtnTbl_Member B LEFT JOIN #rtnTbl_Money A 
		--FROM #rtnTbl_Member B LEFT JOIN #rtnTbl_Money A 
		ON A.DateInfo = B.DateInfo
	)
	SELECT TotalCount = COUNT(1) OVER(), T.* 
	FROM T 
	ORDER BY T.DateInfo DESC 
	OFFSET (@P_pageIndex - 1) * @P_pageSize  ROWS 
	FETCH NEXT @P_pageSize ROWS ONLY;


	DROP TABLE #rtnTbl_Money;
	DROP TABLE #rtnTbl_Member;
	*/
END
