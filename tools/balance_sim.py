import random, sys
# Paper-balance simulator for Krimmis. All numbers are the proposal under test.
P = dict(days=24, acts=3, neigh=12,
  surv_p=0.75, surv_dirt=2, notice_max=3, notice_pen=5,
  inf_cost=3, inf_p3=0.60, inf_p5=0.90, inf_merit=6, inf_fail=-3,
  gift_cost=5, gift_merit=2, gift_debt=8, tithe_div=4, cut=0.5,
  start_coin=30, start_debt=30, interest=0.03, minpay=1,
  store_inc_per_week=1, remove_every=2, line_a=10, line_b=1.7)
def line(P,d): return P['line_a']+P['line_b']*d   # Nice line on day d
def run(policy, P, seed):
    r=random.Random(seed)
    merit=0; dirt=0; coin=P['start_coin']; debt=P['start_debt']
    N=[dict(sus=0,debt=0,naughty=False,alive=True) for _ in range(P['neigh'])]
    warn=0
    for d in range(1,P['days']+1):
        price=P['gift_cost']+(d-1)//7*P['store_inc_per_week']
        for a in range(P['acts']):
            alive=[n for n in N if n['alive']]
            nice=[n for n in alive if not n['naughty']]
            act=policy(d,dirt,coin,price,nice,alive,P)
            if act=='survey' and nice:
                n=min(nice,key=lambda x:x['sus'])
                if r.random()<P['surv_p']: dirt+=P['surv_dirt']
                else:
                    n['sus']+=1
                    if n['sus']>=P['notice_max']: merit-=P['notice_pen']; warn+=1; n['sus']=0
            elif act=='inform' and nice and dirt>=P['inf_cost']:
                spend=5 if dirt>=5 else 3; dirt-=spend
                p=P['inf_p5'] if spend==5 else P['inf_p3']
                n=r.choice(nice)
                if r.random()<p: merit+=P['inf_merit']; n['naughty']=True
                else: merit+=P['inf_fail']
            elif act=='gift' and nice and coin>=price:
                coin-=price; merit+=P['gift_merit']; r.choice(nice)['debt']+=P['gift_debt']
        # night
        for n in alive:
            if n['debt']>0:
                pay=min(n['debt'],-(-n['debt']//P['tithe_div'])); n['debt']-=pay; coin+=int(pay*P['cut'])
        naughty=[n for n in N if n['alive'] and n['naughty']]
        if naughty and d%int(P['remove_every'])==0: r.choice(naughty)['alive']=False
        pay=min(coin,P['minpay']); coin-=pay; debt-=pay
        shortfall=P['minpay']-pay; debt+=shortfall
        debt=int(debt*(1+P['interest']))
    standing=merit-debt//5
    return standing>=line(P,P['days']), standing, merit, debt, sum(n['alive'] for n in N)
def greedy(d,dirt,coin,price,nice,alive,P):
    if dirt>=5 or (dirt>=3 and d>=1): return 'inform'
    if coin>=price+0 and d<=18 and len(nice)>2: return 'gift' if (d%2==0 or dirt>=3) else 'survey'
    return 'survey'
def informer(d,dirt,coin,price,nice,alive,P):
    return 'inform' if dirt>=3 else 'survey'
def gifter(d,dirt,coin,price,nice,alive,P):
    return 'gift' if coin>=price else ('inform' if dirt>=3 else 'survey')
def idle(d,dirt,coin,price,nice,alive,P): return 'none'
if __name__=='__main__':
    for k,v in [a.split('=') for a in sys.argv[1:]]: P[k]=float(v)
    for name,pol in [('greedy',greedy),('informer',informer),('gifter',gifter),('idle',idle)]:
        res=[run(pol,P,s) for s in range(2000)]
        w=sum(x[0] for x in res)/len(res); st=sum(x[1] for x in res)/len(res)
        print(f"{name:9s} win={w:5.1%} avgStanding={st:6.1f} avgMerit={sum(x[2] for x in res)/len(res):6.1f} avgDebt={sum(x[3] for x in res)/len(res):5.1f} alive={sum(x[4] for x in res)/len(res):4.1f}")
    print('line at Eve', line(P,P['days']))
