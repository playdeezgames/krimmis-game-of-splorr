import math, random, sys
# Paper-balance simulator for Krimmis. All numbers are the proposal under test.
# Gifts go on the Company Store card (your own Debt); the recipient feels obliged and returns the favour in Coin
# over the next nights (the Company Store keeps half); Coin pays the card's minimum payment.
P = dict(days=24, acts=3, neigh=12,
  surv_p=0.75, surv_dirt=2, notice_max=3, notice_pen=5,
  inf_cost=3, inf_p3=0.60, inf_p5=0.90, inf_merit=6, inf_fail=-3,
  gift_cost=5, gift_merit=2, gift_debt=12, tithe_div=4, cut=0.5,
  start_coin=30, start_debt=30, interest=0.03, minpay=1, min_rate=0.05, card_limit=50, rung_limit=40,
  store_inc_per_week=1, remove_every=2,
  rung_slope=0.05, rung_price=0, rung_interest=0.002, promo_debt=0, line_a=10, line_b=1.7,
  nosy=3, oblivious=5, grudge_step=1, grudge_cap=1,
  audit_p=0.08, audit_fail=-3, audit_pass=3, tip_p=0.10, tip_dirt=2, santa_p=0.06)
# The street, in house order. Nosy neighbours notice you sooner; oblivious ones later (see the vault roster).
NOSY=[True,False,False,True,False,True,False,True,False,True,True,False]
def fresh(i,P,debt=0,grudge=0):
    return dict(sus=0,debt=debt,naughty=False,alive=True,lim=P['nosy'] if NOSY[i%12] else P['oblivious'],grudge=grudge)
def line(P,d,rung=0): return P['line_a']+(P['line_b']+P['rung_slope']*rung)*d   # Nice line on day d
def run(policy, P, seed, carry=None, rung=0, rng=None):
    r=rng or random.Random(seed)
    merit=0; dirt=0; coin=P['start_coin']; debt=P['start_debt']
    N=[fresh(i,P) for i in range(P['neigh'])]
    if carry:
        coin,debt,N=carry
    warn=0; santa=False
    for d in range(1,P['days']+1):
        acts=P['acts']-(1 if santa else 0); santa=False
        price=P['gift_cost']+(d-1)//7*P['store_inc_per_week']+P['rung_price']*rung
        for a in range(acts):
            alive=[n for n in N if n['alive']]
            nice=[n for n in alive if not n['naughty']]
            limit=P['card_limit']+P['rung_limit']*rung
            act=policy(d,dirt,debt+price<=limit,price,nice,alive,P)
            if act=='survey' and nice:
                n=min(nice,key=lambda x:x['sus'])
                if r.random()<P['surv_p']: dirt+=P['surv_dirt']
                else:
                    n['sus']+=1
                    if n['sus']>=max(1,n['lim']-min(n['grudge'],P['grudge_cap'])): merit-=P['notice_pen']; warn+=1; n['sus']=0
            elif act=='inform' and nice and dirt>=P['inf_cost']:
                spend=5 if dirt>=5 else 3; dirt-=spend
                p=P['inf_p5'] if spend==5 else P['inf_p3']
                n=r.choice(nice)
                if r.random()<p: merit+=P['inf_merit']; n['naughty']=True
                else: merit+=P['inf_fail']; n['grudge']+=P['grudge_step']
            elif act=='gift' and nice and debt+price<=limit:
                debt+=price; merit+=P['gift_merit']; r.choice(nice)['debt']+=P['gift_debt']
        # night
        for n in alive:
            if n['debt']>0:
                pay=min(n['debt'],-(-n['debt']//P['tithe_div'])); n['debt']-=pay; coin+=int(pay*P['cut'])
        naughty=[n for n in N if n['alive'] and n['naughty']]
        if naughty and d%int(P['remove_every'])==0: r.choice(naughty)['alive']=False
        due=max(P['minpay'],math.ceil(debt*P['min_rate']))
        pay=min(coin,due); coin-=pay; debt-=pay
        shortfall=due-pay; debt+=shortfall
        debt=int(debt*(1+P['interest']+P['rung_interest']*rung))
        if d<P['days']:   # one random event a night, never on Krimmis Eve
            x=r.random()
            if x<P['audit_p']:
                merit+=P['audit_pass'] if merit-debt//5>=line(P,d,rung) else P['audit_fail']
            elif x<P['audit_p']+P['tip_p']: dirt+=P['tip_dirt']
            elif x<P['audit_p']+P['tip_p']+P['santa_p']: santa=True
    standing=merit-debt//5
    run.last=(coin,debt,N)
    return standing>=line(P,P['days'],rung), standing, merit, debt, sum(n['alive'] for n in N)
def promote(P, state):
    # A win: Head Elf. The Debt carries and grows, the Coin carries, survivors keep their Debt and grudges,
    # the removed are replaced by fresh neighbours, and everyone starts the new List as Nice.
    coin,debt,N=state
    N=[fresh(i,P,n['debt'],n['grudge']) if n['alive'] else fresh(i,P) for i,n in enumerate(N)]
    return (max(coin,P['start_coin']),debt+P['promo_debt'],N)
def years(policy,P,seed,max_years=8):
    r=random.Random(seed); carry=None; rung=0
    while rung<max_years:
        res=run(policy,P,seed,carry,rung,r)
        if not res[0]: return rung   # rungs climbed before coal
        carry=promote(P,run.last); rung+=1
    return rung
def greedy(d,dirt,afford,price,nice,alive,P):
    if dirt>=5 or (dirt>=3 and d>=1): return 'inform'
    if afford and d<=18 and len(nice)>2: return 'gift' if (d%2==0 or dirt>=3) else 'survey'
    return 'survey'
def informer(d,dirt,afford,price,nice,alive,P):
    return 'inform' if dirt>=3 else 'survey'
def gifter(d,dirt,afford,price,nice,alive,P):
    return 'gift' if afford else ('inform' if dirt>=3 else 'survey')
def idle(d,dirt,afford,price,nice,alive,P): return 'none'
if __name__=='__main__':
    for k,v in [a.split('=') for a in sys.argv[1:]]: P[k]=float(v)
    for name,pol in [('greedy',greedy),('informer',informer),('gifter',gifter),('idle',idle)]:
        res=[run(pol,P,s) for s in range(2000)]
        w=sum(x[0] for x in res)/len(res); st=sum(x[1] for x in res)/len(res)
        print(f"{name:9s} win={w:5.1%} avgStanding={st:6.1f} avgMerit={sum(x[2] for x in res)/len(res):6.1f} avgDebt={sum(x[3] for x in res)/len(res):5.1f} alive={sum(x[4] for x in res)/len(res):4.1f}")
    print('line at Eve', line(P,P['days']))
    for name,pol in [('greedy',greedy),('gifter',gifter)]:
        ys=[years(pol,P,s) for s in range(1000)]
        dist=[sum(1 for y in ys if y==k)/len(ys) for k in range(0,6)]
        print(f"{name:9s} climbs: mean {sum(ys)/len(ys):.2f}; coal at rung 0..5: "+" ".join(f"{d:4.0%}" for d in dist))
