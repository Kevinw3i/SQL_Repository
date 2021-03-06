USE [EuroStar]
GO
/****** Object:  StoredProcedure [dbo].[SP_Member_CheckBalance]    Script Date: 2018/11/9 下午 02:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Kevin
-- Create date: 2018/11/6
-- Description:	
-- =============================================
/*
 Exec SP_Member_CheckBalance @P_m_Idx = 2000351
*/
ALTER PROCEDURE [dbo].[SP_Member_CheckBalance]
	@P_m_Idx	int

AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE @withdrawLimitPercent float

	SELECT @withdrawLimitPercent = Convert(float, cast([value] as varchar(10)))
	FROM [dbo].[T_SiteConfig]
	WHERE [key] = 'withdrawLimit'

	--看還原資料
	SELECT a.m_Idx, 
	  a.balance as TMBbalance ,a.payment as TMBPayment , a.deposit as TMBDeposit , a.turnover as TMBturnover , a.revenue as TMBrevenue,
	  b.total balance, b.[payment], b.orgDeposit, b.turnover
	  , b.revenue, b.total-(@withdrawLimitPercent/100)*b.orgDeposit + b.turnover as withdrawLimit
	  , (@withdrawLimitPercent/100)*b.orgDeposit - b.turnover as nonWithdrawLimit 
	from [dbo].[T_Member] as a
	join (select *
	  from(
		select c_key,sum(depositPrice) [total],sum(deposit) [deposit],sum(payment) [payment],sum(orgDeposit) orgDeposit
		  ,sum(turnover) turnover, sum(revenue) revenue
		from (
		  --調帳 
		  select c_key,depositPrice,depositPrice [deposit],0 payment, 0 orgDeposit, 0 turnover, 0 revenue  from t_depositinfo WITH(nolock)
		  where status='2' or (status = '1' and etc ='Request Adjustment' and depositPrice<0)

		  union all
		  -- 前台申請提款寫入T_PaymentInfo
		  -- Risk 拒絕 Status寫入3 
		  -- Risk 接受 Status寫入1
		  select c_key,price*-1 [depositprice],0 [deposit], price [payment], 0 orgDeposit, 0 turnover, 0 revenue  from T_PaymentInfo WITH(nolock)
		  where (status='2' or status ='1'or status='0')

		  union all
		  -- PM:Payment to Member (同意給會員金錢)
		  select c_key,0 depositPrice,0 [deposit],0 payment, depositPrice orgDeposit, 0 turnover, 0 revenue from t_depositinfo WITH(nolock)
		  where  status='2' AND p_status = 'PM'

		  union all
		  -- BI: Bet in (下注)
		  select c_key,0 depositPrice,0 [deposit],0 payment, 0 orgDeposit, depositPrice * -1 turnover, 0 revenue from t_depositinfo WITH(nolock)
		  where status='2' AND p_status = 'BI'

		  union all
		  -- BO: Bet out(win or return) 贏的話金額含本金，輸的話回0
		  select c_key,0 depositPrice,0 [deposit],0 payment, 0 orgDeposit, 0 turnover, depositPrice revenue from t_depositinfo WITH(nolock)
		  where status='2' AND p_status = 'BO'
		)sub
	  group by c_key) a
	) b on b.c_Key = a.m_Idx
	Where a.m_Idx = @P_m_Idx
	--And   a.balance != b.total
	Order by a.m_Idx;

END


