library(concord)
options(digits=2)

holsti = function(m){
		cell = coincidence.matrix(m)$coincidence.matrix
		return(sum(diag(cell))/sum(cell))
	}




ac1 = function(m){
	cell = coincidence.matrix(m)$coincidence.matrix
	a = cell[1,1]
	b = cell[1,2]
	c = cell[2,1]
	d = cell[2,2]
	n = sum(cell)
	p = sum(diag(cell))/sum(cell)
	p1=(2*a+b+c)/(2*n)
	#print(p1)
	#pe = 0
	#for (i in ncol(cell)){
   # 	#pe = pe + (sum(cell[i,])/n)*(sum(cell[,i])/n)
   #    ro = sum(cell[i,])/n
   #    co = sum(cell[,i])/n
   #    print(c(ro,co))
#	}
	e=2*p1*(1-p1)	
	AC1=(p-e)/(1-e)
	return(AC1)
	}
	
	
	ac1_raw = function(a,b,c,d){
	n = a+b+c+d
	p=(a+d)/n
	p1=(2*a+b+c)/(2*n)
	e=2*p1*(1-p1)
	AC1=(p-e)/(1-e)
	return(AC1)
	}
	
kalpha = function(m){
	return(kripp.alpha(m)$statistic)
	}

reli = function(m){
	if(ncol(m) < 5){return(NA)}
	#return(c(holsti(m),kalpha(m),rse(m),eval(m),ncol(m),as.vector(table(m[1,],m[2,]))))
	return(c(holsti(m),kalpha(m),coincidence.matrix(m)$nmatchval/2,as.vector(table(m[1,],m[2,]))))
	}

check_coders = function(m){
	n = nrow(m)
	rel = c()
	for (i in seq(1,n,1)){
		rel = c(rel, kripp.alpha(m[-i,])$statistic )
		}
	return(rel)
	}
	
eval = function(m){
	cell = table(m[1,],m[2,])
	tp = cell[1,1]
	fn = cell[1,2]
	fp = cell[2,1]
	tn = cell[2,2]
	n = sum(cell)
	acc=(tp+tn)/n
	prec = tp / (tp + fp)
	rec = tp / (tp + fn)
	spec = tn / (tn + fp)
	f = (2*prec*rec)/(prec+rec)
	return(c(prec,rec))
	}


rse <- function(m){
	x = table(m[1,],m[2,])
	n = c(x[upper.tri(x)],x[lower.tri(x)])
	sn=sum(n)
	ns=sum(n^2)
	c=sum(n)/nrow(x)
	max = (sn^2)*(c-1)
	top = (c*ns)-(sn^2)
	return(sqrt(top/max))
	}
