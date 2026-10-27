"""Puts each rendered board next to its app golden: <out_dir>/pairs/<Group>_<Board>.png.

Usage: python3 pairs.py <out_dir> apps/mobile   (after render.py; needs Pillow)
Goldens have no status bar and draw shadows as hard bands: compare spacing from
the first element, not absolute offsets.
"""
import sys, os
from PIL import Image, ImageDraw
S, G = sys.argv[1], sys.argv[2]
M = {
 'A': [('ObWelcome','auth/a1_welcome'),('ObAccount','auth/a1_sign_up'),('ObGoals','auth/a1_goals'),('ObNeeds','auth/a1_habits'),('ObBudget','auth/a1_budget'),('ObSetup','auth/a1_wallets'),('ObHome','home/overview_firstRun'),('AuLogin','auth/a1_login'),('AuRegister','auth/a1_register'),('AuVerify','auth/a1_verify'),('ObPin','auth/a1_pin'),('ObPinConfirm','auth/a1_pin_confirm'),('ObBiometric','auth/a1_biometric'),('AuForgot','auth/a1_forgot'),('AuReset','auth/a1_reset'),('LockScreen','auth/a1_lock')],
 'B': [('BHome','home/overview_ready'),('BHidden','home/overview_hidden'),('BMulti','home/overview_multi'),('BDebt','home/overview_debt'),('BNewMonth','home/overview_newMonth'),('BLoading','home/overview_loading'),('BOffline','home/overview_offline'),('BError','home/overview_error')],
 'C': [('TxList','transactions/c1_list'),('TxSearch','transactions/c1_search'),('TxFilter','transactions/c1_filter'),('TxNoResult','transactions/c1_no_result'),('TxDetail','transactions/c1_detail'),('TxDeleted','transactions/c1_deleted'),('TxTrash',None),('TxExpense','transactions/c2_expense'),('TxCategory','transactions/c2_category'),('TxMore','transactions/c2_details'),('TxTags','transactions/c2_tags'),('TxTransfer','transactions/c2_transfer'),('TxSaved',None)],
 'D': [('WList','wallets/d1_list'),('WSort','wallets/d1_sort'),('WDetail','wallets/d1_detail'),('WCredit','wallets/d1_credit'),('WAdd','wallets/d2_add'),('WAddCredit','wallets/d2_add_card'),('WDaySheet','wallets/d2_day_popup'),('WEdit','wallets/d2_edit_locked'),('WHidden','wallets/d1_hidden')],
 'E': [('CatList','categories/e1_list'),('CatAdd','categories/e2_add'),('CatParent','categories/e2_parent_sheet'),('CatIcons','categories/e2_icon_sheet'),('CatEdit','categories/e2_edit'),('CatDelete','categories/e2_delete'),('CatHidden','categories/e1_hidden')],
 'F': [('RepMonth','reports/f1_month'),('RepWallets','reports/f1_wallets'),('RepCategory','reports/f2_category'),('RepRange','reports/f2_range'),('RepEmpty','reports/f1_empty')],
 'G': [('MeHome','settings/g1_me'),('MeProfile','settings/g1_profile'),('MeTheme','settings/g1_theme'),('MeSecurity','settings/g1_security'),('MeSessions','settings/g1_sessions'),('MeLogout','settings/g1_logout'),('MeTags','settings/g2_tags'),('MeFeedback','settings/g2_feedback'),('MeFeedbackSent','settings/g2_thanks'),('MeFaq','settings/g2_faq'),('MeNotify','settings/g2_notify')],
 'H': [('SyncBanner','sync/h1_list'),('SyncCenter','sync/h1_center'),('SyncRunning','sync/h1_sending'),('SyncDone','sync/h1_done'),('SyncConflict','sync/h2_compare'),('SyncDuplicate','sync/h2_duplicate'),('SyncDiscard','sync/h1_discard'),('SyncUpdate','sync/h1_update')],
}
os.makedirs(f'{S}/pairs', exist_ok=True)
for grp, items in M.items():
  for board, gold in items:
    d = Image.open(f'{S}/design/{board}.png').convert('RGB')
    a = Image.open(f'{G}/test/features/{gold.split("/")[0]}/goldens/{gold.split("/")[1]}.png').convert('RGB') if gold else Image.new('RGB',(390,200),'white')
    h = max(d.height, a.height)
    out = Image.new('RGB', (d.width + a.width + 30, h + 30), (255,0,255))
    out.paste(d, (0, 30)); out.paste(a, (d.width + 30, 30))
    dr = ImageDraw.Draw(out); dr.text((6,8),'DESIGN '+board,fill='black'); dr.text((d.width+36,8),'APP '+(gold or 'NO GOLDEN'),fill='black')
    out.save(f'{S}/pairs/{grp}_{board}.png')
print('ok')
