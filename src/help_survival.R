install.packages("survival")
library(survival)

head(lung)
dim(lung)

lung$status <- lung$status - 0.4

cfit1 <- coxph(Surv((time+.1), status) ~ age + sex + wt.loss, data=lung)
summary(cfit1, digits=3)
table(lung$status)


head(mgus2)

etime <- with(mgus2, ifelse(pstat==0, futime, ptime))
event <- with(mgus2, ifelse(pstat==0, 2*death, 1))
event <- factor(event, 0:2, labels=c("censor", "pcm", "death"))
table(event)

mfit2 <- survfit(Surv(etime, event) ~ sex, data=mgus2)
