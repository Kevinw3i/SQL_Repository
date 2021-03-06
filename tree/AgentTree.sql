 
 ;With tempTree As(
  Select 
    m.m_idx ,
    m.m_id,
	m.partnerType,
    Convert(nvarchar(150),m.m_idx) as path,
    Convert(nvarchar(150),m.m_id) as Name_path
  From T_Member m
  join T_MemberProfit mp On m.m_Idx = mp.m_Idx
  Where m.m_idx = 2000351 

  UNION  All

  Select 
    DataSource.m_Idx,
    DataSource.m_Id,
	DataSource.partnerType,
    Convert(nvarchar(150),CONCAT(TreeNode.Path , '->',DataSource.m_Idx)) as Path,
    Convert(nvarchar(150),CONCAT(TreeNode.Name_path , '->',DataSource.m_Id)) as Name_path
    From T_Member DataSource
    Join tempTree TreeNode   On DataSource.ref_m_Idx = TreeNode.m_Idx
	Join T_MemberProfit TMP  On DataSource.m_Idx = TMP.m_Idx 

  )
  SELECT tt.m_Idx,tt.m_Id, tt.partnerType, tt.path , tt.Name_path FROM tempTree tt
  Join T_MemberProfit mp On tt.m_Idx = mp.m_Idx
  Order by tt.m_Idx Asc


  Select m_idx , m_id , partnerType , ref_m_Idx From T_Member Where m_idx in (2000438,2000443) 