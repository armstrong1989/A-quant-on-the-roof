library(quantstrat)
# system settings
currency("USD")
stock("SPY",currency="USD",multiplier=1)

initDate <- '1997-12-31'
startDate <- '2008-01-01'
endDate <-  '2014-06-30'
initEq <- 1e6
Sys.setenv(TZ="UTC")
getSymbols('SPY', from=startDate, to=endDate, index.class="POSIXct", adjust=T)

SPY=to.monthly(SPY, indexAt='endof', drop.time=FALSE) 
SPY$SMA10m <- SMA(Cl(SPY), 10)

# initialise portfolio, account
qs.strategy <- "qsFaber"
# remove strategy etc. if this is a re-run
rm.strat(qs.strategy) 
portfolio.st="Portfolio.st"
initPortf(portfolio.st,symbols = 'SPY', initDate=initDate)
account.st = "Account.st"
initAcct(account.st,portfolios=portfolio.st, initDate=initDate, initEq=initEq)
# initialize orders container
initOrders(portfolio=portfolio.st,initDate=initDate)
# instantiate a new strategy object
strategy(qs.strategy,store=TRUE)

##Add a 10-month simple moving average
add.indicator(strategy = qs.strategy, name = "SMA",
              arguments = list(x = quote(Cl(mktdata)), n=5), label="SMA5")

add.indicator(strategy = qs.strategy, name = "SMA",
              arguments = list(x = quote(Cl(mktdata)), n=20), label="SMA20")

##Add a RSI indicator
add.indicator(strategy = qs.strategy, name = "RSI",
              arguments = list(price=quote(Cl(mktdata)), n=2), label="RSI2")

##Adding signals to a strategy
add.signal(qs.strategy,name="sigCrossover",
           arguments = list(columns=c("SMA5","SMA20"),relationship="gt"), label="S5.gt.S20")


add.signal(qs.strategy,name="sigCrossover",
           arguments = list(columns=c("SMA5","SMA20"),relationship="lt"), label="S5.lt.S20")

add.signal(qs.strategy,name = "sigThreshold",
           arguments = list(column="RSI2",threshold= 65,relationship="lt",cross=FALSE),label = "RSI.lt.65")


test_init = applyIndicators(qs.strategy,mktdata=SPY)  
test=applySignals(strategy = qs.strategy,mktdata=test_init)

add.signal(qs.strategy, name = "sigFormula",
           arguments = list(formula="S5.gt.S20 & RSI.lt.65", cross=FALSE),
           label = "Buysignal")

##go long 
add.rule(qs.strategy, name='ruleSignal',
         arguments = list(sigcol="Buysignal", sigval=TRUE, orderqty=1000, ordertype='market', orderside='long'),
         type='enter')
##exit 
add.rule(qs.strategy, name='ruleSignal',
         arguments = list(sigcol="S5.lt.S20", sigval=TRUE, orderqty='all', ordertype='market', orderside='long'),
         type='exit')

applyStrategy(strategy=qs.strategy, portfolios=portfolio.st)
updatePortf(portfolio.st)
updateAcct(account.st)
updateEndEq(account.st)

chart.Posn(portfolio.st, Symbol = 'SPY', Dates = '1998::', TA='add_SMA(n=10,col=4, on=1, lwd=2)')





