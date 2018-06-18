pragma solidity ^0.4.21;

contract PartTime {

    uint256 public totalJob;
    uint256 constant public MINIUM_SALARY = 0.1 ether;

    struct Job{
        uint256 id;
        address creator;
        address labor;
        uint256 salary;
        bytes title;
        bytes description;
        uint256 start;
        uint256 end;
        uint256 timeOut;
        bool completed;
    }

    event NewJob(
        uint256 indexed id,
        address creator,
        uint256 salary,
        uint256 timeOut
    );

    event TakeJob(
        uint256 indexed id,
        address indexed labor
    );

    //event job done
    event Done(uint256 jobId, address indexed labor);

    //event cancel create job
    event CancelCreatedJob(uint256 indexed id, address creator);

    //event job failed
    event Failed(uint256 jobId, address indexed labor);

    //event paid
    event Paid(address indexed creator, address indexed labor, uint256 value);

    modifier onlyHaveFund {
        require(msg.value > MINIUM_SALARY);
        _;
    }

    //valid timeOut should be greater than 3 days
    modifier onlyValidTimeout(uint256 timeOut) {
        require(timeOut > 3 days);
        _;
    }

    //valid jobid which existed
    modifier onlyValidId(uint256 jobId) {
        require(jobId < totalJob);
        _;
    }

    modifier onlyValidMortgage(uint256 jobId) {
        require(msg.value > jobData[jobId].salary/10);
        _;
    }

    // check is it a taked job
    modifier onlyValidJob(uint256 jobId) {
        require(jobData[jobId].end == 0);
        require(jobData[jobId].start == 0);
        _;
    }

    modifier onlyCreator(uint256 jobId) {
        require(jobData[jobId].creator == msg.sender);
        _;
    }

    //only not completed
    modifier onlyNotCompleted(uint256 jobId) {
        require(jobData[jobId].completed == false);
        _;
    }

    //only labor is accepted
    modifier onlyLabor(uint256 jobId) {
        require(jobData[jobId].labor == msg.sender);
        _;
    }

    mapping (uint256 => Job) public jobData;


    function() public payable {
        revert();
    }


    function createJob(uint256 timeOut, bytes title, bytes description) public onlyHaveFund onlyValidTimeout(timeOut) payable returns (uint256 jobId){
        Job memory newJob;

        jobId = totalJob;

        newJob.id = jobId;
        newJob.title = title;
        newJob.timeOut = timeOut;
        newJob.salary = msg.value;
        newJob.description = description;
        newJob.creator = msg.sender;

        //trigger event
        emit NewJob(jobId, msg.sender, msg.value, timeOut);

        //append newJob to jobData
        jobData[totalJob++] = newJob;

        return jobId;
    }

    // Creator able to cancel his own jobs
    function cancel(uint jobId) public onlyCreator(jobId) onlyValidJob(jobId) returns(bool){
        jobData[jobId].end = block.timestamp;

        //smart contract have to return mortage
        jobData[jobId].creator.transfer(jobData[jobId].salary);
        emit CancelCreatedJob(jobId, msg.sender);
        return true;
    }

        // labor take job
    function takeJob(uint256 jobId) public payable onlyValidMortgage(jobId) onlyValidId(jobId) onlyValidJob(jobId) returns (bool){

        jobData[jobId].start = block.timestamp;
        jobData[jobId].labor = msg.sender;

        emit TakeJob(jobId,msg.sender);
        return true;
    }

    function viewJob(uint256 jobId) public onlyValidId(jobId) constant returns (uint256 id, address creator, uint256 salary, uint256 start, uint256 end, uint256 timeOut, bytes title, bytes description){
        Job memory jobReader = jobData[jobId];
        return (jobReader.id, jobReader.creator, jobReader.salary, jobReader.start, jobReader.end, jobReader.timeOut, jobReader.title, jobReader.description);
    }

    // labor had finished their job
    function finished(uint256 jobId) public onlyValidId(jobId) onlyLabor(jobId) returns(bool){
        jobData[jobId].end = block.timestamp;
        emit Done(jobId, msg.sender);
        return true;
    }

    //Labor had failed their job
    function failed(uint256 jobId) public onlyValidId(jobId) onlyLabor(jobId) returns(book) {
        Job memory mJob = jobData[jobId];
        uint256 value = (mJob.salary/10)/2;

        mJob.start = 0;
        mJob.labor = 0;

        //update data set
        jobData[jobId] = mJob;

        //Labor lost 1/2 their mortage
        msg.sender.transfer(value);

        //Creator receive 1/2 labor's mortage
        mJob.creator.transfer(value);
        emit Failed(jobId, msg.sender);
        return true;
    }

    //after labor have finished their job, creator must pay them money

    function pay(uint256 jobId) public onlyValidId(jobId) onlyCreator(jobId) onlyNotCompleted(jobId) returns(bool) {
        uint value;

        value = jobData[jobId].salary;
        value = value + (value/10);

        //mark that job as completed
        jobData[jobId].completed = true;

        //transfer fund and mortage to labor
        jobData[jobId].labor.transfer(value);
        emit Paid(jobData[jobId].creator, jobData[jobId].labor, value);
        return true;
    }
}