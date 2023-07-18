﻿ALTER VIEW  V_YYSG_SGKC AS
select DW_BM, PZ_ID ,PZ_MC ,ISNULL(TD_PZ_ID,PZ_ID) as TD_PZ_ID,ISNULL(TD_PZ_MC,PZ_MC) as TD_PZ_MC ,ZBLX_ID, ZBLX, DJ_ID, DJ_BM,ISNULL(ZL,0) AS ZL   from 
(

SELECT DW_BM, PZ_ID, PZ_MC, ZBLX_ID, ZBLX, DJ_ID, DJ_BM, ZL
FROM (SELECT SG.DW_BM, SG.PZ_ID, SG.PZ_MC, SG.ZBLX_ID, SG.ZBLX, SG.DJ_ID, SG.DJ_BM, ISNULL(SG.ZL, 0) - ISNULL(YB.ZL, 0) - ISNULL(LK.ZL,0) AS ZL
FROM (SELECT DW_BM,PZ_ID,PZ_MC,ZBLX_ID,ZBLX,DJ_ID,DJ_BM,ISNULL(SUM(ZL),0) AS ZL FROM (
-- 未删除的磅码重量
SELECT YD_BM AS DW_BM, PZ_ID, PZ_MC, ZBLX_ID, ZBLX, DJ_ID, DJ_BM, ZL FROM dbo.YYSG_DJBM
WHERE SFSC = 0 
UNION ALL
-- 盘点产生的盈亏重量
SELECT A.CD_BM AS DW_BM,B.PZ_ID,B.PZ_MC,B.ZBLXID AS ZBLX_ID,B.ZBLX,DJ_ID,DJ_BM, B.YKZL AS ZL FROM YYSG_SYPD AS A 
INNER JOIN YYSG_SYPD_MX AS B ON 
A.SYPD_ID = B.SYPD_ID AND A.SFSC = 0 AND A.SHZT=2 AND B.SFSC = 0 AND B.YKZL <> 0) AS A     --修改记录：此处条件新增AND A.SHZT=2 表示 只算审核通过的盘点量  木色小罗 2016.8.1
GROUP BY DW_BM,PZ_ID,PZ_MC,ZBLX_ID,ZBLX,DJ_ID,DJ_BM
) AS SG LEFT OUTER JOIN (
-- 未作废的烟包重量        --修改记录：此处ISNULL(c_PZTD.SG_PZ_ID,YYSG_YB.PZ_ID)  钟豪 2016.08。21
SELECT YD_BM AS DW_BM,ISNULL(c_PZTD.SG_PZ_ID,YYSG_YB.PZ_ID) AS PZ_ID,ISNULL(c_PZTD.SG_PZ_MC,YYSG_YB.PZ_MC) AS PZ_MC, ZBLX_ID, ZBLX, DJ_ID, DJ_BM, ISNULL(SUM(ZL), 0) AS ZL
FROM dbo.YYSG_YB 
 left join c_PZTD  on c_PZTD.TD_PZ_ID=YYSG_YB.PZ_ID 
WHERE YYSG_YB.SFSC = 0
GROUP BY YD_BM, ISNULL(c_PZTD.SG_PZ_ID,YYSG_YB.PZ_ID), ISNULL(c_PZTD.SG_PZ_MC,YYSG_YB.PZ_MC) , DJ_ID, DJ_BM, ZBLX_ID, ZBLX
) AS YB ON SG.PZ_ID = YB.PZ_ID AND SG.ZBLX_ID = YB.ZBLX_ID AND SG.DJ_ID = YB.DJ_ID
LEFT OUTER JOIN (
-- 被设备锁定的烟叶重量
SELECT DW_BM,PZ_ID,PZ_MC,ZBLX_ID,ZBLX=ZBLX_MC,DJ_ID,DJ_BM,ISNULL(SUM(ZL),0) AS ZL FROM YYSG_DBSD WHERE SD_ZT = 1 AND SFSC = 0
GROUP BY DW_BM,PZ_ID,PZ_MC,ZBLX_ID,ZBLX_MC,DJ_ID,DJ_BM
) AS LK ON SG.PZ_ID = LK.PZ_ID AND SG.ZBLX_ID = LK.ZBLX_ID AND SG.DJ_ID = LK.DJ_ID
) AS YL WHERE (ZL > 0)
) sgkcj  left join c_PZTD  on c_PZTD.SG_PZ_ID=sgkcj.PZ_ID  where ISNULL(c_PZTD.SFSC,0)=0
