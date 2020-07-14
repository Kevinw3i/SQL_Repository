
Declare @m_idx int

Set @m_idx = 2000000

;With CTE As(
Select a.Date , a.Price , a.etc ,row_number() over(order by a.Date Asc) as 'Row_Count' ,refGrpbetseq
From (
Select  Cast(depositDate As Date)As Date, depositPrice As Price, etc ,refGrpbetseq
From T_DepositInfo TD
Where TD.c_Key = @m_idx And TD.status = 2

Union All

Select  Cast(payDate As Date)As Date, (price * -1)  As Price, ('Withdraw') etc , 0 As refGrpbetseq
From T_PaymentInfo TP
Where TP.c_Key = @m_idx And TP.status = 2
) a

)

Select A.Row_Count,A.Date,A.Price,A.etc , SUM(B.Price) As '累加' , A.refGrpbetseq
From CTE A
Inner Join CTE B On B.Row_Count <= A.Row_Count
Group by A.Row_Count, A.Date,A.Price , A.refGrpbetseq,A.etc 
order by Row_Count


-- 驗證用
SELECT a.m_Idx, 
	  a.balance as '當前T_Member Balance' ,
	  b.total as '計算出來的 Balance',
	  b.total -  a.balance As diff
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
		  
		)sub
	  group by c_key) a
	) b on b.c_Key = a.m_Idx
	Where a.m_Idx = @m_idx
	Order by a.m_Idx;