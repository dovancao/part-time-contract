var Partime = artifacts.require("./PartTime.sol");
var instancePartime;
var jobIndex = 0;

function createTx(from, to, value = 0, gas= 1000000, gasPrice = 2000000){
    return {
        from: from,
        to: to,
        gas: gas,
        gasPrice: gasPrice,
        value: value
    };
}

function stringMe(data){
    return Buffer.from(data.substr(2), 'hex').toString();
}


async function showJobData(id){
    let fields = ['id', 'creator', 'salary', 'start', 'end', 'timeOut', 'title', 'description', 'labor'];
    let data = await instancePartime.jobData(id);
    console.log('   Job's details: ');
    for(let i = 0; i< data.length; i++){
        if(i == 6 || i == 7){
            console.log('    ', fields[i] + ":", stringMe(data[i].valueOf()));
        }else{
            console.log('     ', fields[i] + ":", data[i].valueOf());
        }
    }
}

var creator, labor, anonymos;

contract('Partime', function(accounts){

    it('should have 0 total part time job', async function (){
         instancePartime = await Partime.deployed().then(function (instance){
            return instance;
        });
        //Alias
        creator = accounts[1];
        labor = accounts[2];
        anonymos = accounts[3];
        let totalJob = await instancePartime.totalJob();
        assert.equal(totalJob.valueOf(), 0);
    });

    it(' Creator should able to add new job', async function(){
        let timeStamp = web3.toBigNumber((((new Date()).getTime()/1000 | 0) +432000);
        //create a part time job
        instancePartime.createJob(
                timeStamp,
                "Write Article" + jobIndex,
                "Need a freelancer for write an article" +jobIndex,
                createTx(creator, instancePartime.address, web3.toWei("1",'ether')));

                //increase job count
                jobIndex++;
                let totalJob = await instancePartime.totalJob();
                await showJobData(totalJob.sub(1));
                assert.equal(totalJob.valueOf(), 1);
        });

    it('anonymous actor should not able to cancel created job', async function () {
        let totalJob = await instancePartime.totalJob();
        let error = false;
        try {
            await instancePartime.cancel(totalJob.sub(1), createTx(anonymos,instancePartime.address));
        }catch(e){
            error = true;
        }
        assert.equal(error, true);
    });

    it('creator should able to cancel his created job', async function (){
        let totalJob = await instancePartime.totalJob();
        await instancePartime.cancel(totalJob.sub(1), createTx(creator, instancePartime.address));
        await showJobData(totalJob.sub(1));
    })

    it(' Creator should able to add new job', async function(){
            let timeStamp = web3.toBigNumber((((new Date()).getTime()/1000 | 0) +432000);
            //create a part time job
            instancePartime.createJob(
                    timeStamp,
                    "Write Article" + jobIndex,
                    "Need a freelancer for write an article" +jobIndex,
                    createTx(creator, instancePartime.address, web3.toWei("1",'ether')));

                    //increase job count
                    jobIndex++;
                    let totalJob = await instancePartime.totalJob();
                    await showJobData(totalJob.sub(1));
                    assert.equal(totalJob.valueOf(), 2);
            });


    it('labor should able to take available job', async function(){
        let totalJob = await instancePartime.totalJob();
        //take a parttime job
        instancePartime.take(totalJob.sub(1), createTx(labor, instancePartime.address, web3.toWei('0.1','ether')));
        let data = await instancePartime.jobData(totalJob.sub(1));
        await showJobData(totalJob.sub(1));
        assert.equal(data[8].valueOf(), labor)
    });



});

