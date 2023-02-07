// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DecentraTweet {

    event ProfileCreated(address indexed user, string userName, string bio);
    event TweetCreated(uint indexed tweetId, string content, string creator);
    event TweetUpdated(uint indexed tweetId, string content);
    event TweetDeleted(uint indexed tweetId);

    error DoesNotOwnTweet(address user, uint id);
    error NotUser(address addr);

    struct Profile {
        address addr;
        string userName;
        string bio;
    }

    mapping(address => Profile) public userProfiles;
    mapping(address => bool) private isUser;

    struct Tweet {
        uint id;
        string content;
        string creator;
    }

    uint nextTweetId = 1;
    mapping(address => Tweet[]) public userTweets;
    mapping(uint => uint) private indexOfTweetId;
    mapping(address => mapping(uint => bool)) private userOwnsTweet;

    modifier onlyTweetOwner(address _userAddr, uint _id) {
        if(!userOwnsTweet[_userAddr][_id]) {
            revert DoesNotOwnTweet(_userAddr, _id);
        }
        _;
    }

    modifier onlyUser(address _userAddr) {
        if(!isUser[_userAddr]) {
            revert NotUser(_userAddr);
        }
        _;
    }
    
    function signUp(string memory _userName, string memory _bio) external {
        Profile memory profile;
        profile.addr = msg.sender;
        profile.userName = _userName;
        profile.bio = _bio;
        userProfiles[msg.sender] = profile;
        isUser[msg.sender] = true;
        emit ProfileCreated(msg.sender, _userName, _bio);
    }

    function getProfile(address _userAddr) external view returns (Profile memory) {
        return userProfiles[_userAddr];
    }

    function createTweet(string memory _content) external onlyUser(msg.sender) {
        Profile memory profile = userProfiles[msg.sender];
        Tweet memory tweet;
        tweet.id = nextTweetId;
        tweet.content = _content;
        tweet.creator = profile.userName;
        indexOfTweetId[nextTweetId] = userTweets[msg.sender].length;
        userTweets[msg.sender].push(tweet);
        userOwnsTweet[msg.sender][nextTweetId] = true;
        nextTweetId++;
        emit TweetCreated(nextTweetId - 1, _content, profile.userName);
    }

    function getUserTweetByAddressAndId(address _userAddr, uint _id) 
        external view returns (Tweet memory) {
        Tweet memory tweet;
        for(uint i = 0; i < userTweets[_userAddr].length; i++) {
            if(userTweets[_userAddr][i].id == _id) {
                tweet = userTweets[_userAddr][i];
            }
        }
        return tweet;
    }

    function getAllUserTweets(address _userAddr) external view returns (Tweet[] memory) {
        Tweet[] memory tweets = new Tweet[](userTweets[_userAddr].length);
        for(uint i = 0; i < userTweets[_userAddr].length; i++) {
            Tweet memory tweet = userTweets[_userAddr][i];
            tweets[i] = tweet;
        }
        return tweets;
    }

    function updateTweet(uint _id, string memory _content) 
        external onlyTweetOwner(msg.sender, _id) {
        for(uint i = 0; i < userTweets[msg.sender].length; i++) {
            if(userTweets[msg.sender][i].id == _id) {
                userTweets[msg.sender][i].content = _content;
            }
        }
        emit TweetUpdated(_id, _content);
    }

    function deleteTweet(uint _id) external onlyTweetOwner(msg.sender, _id) {
        delete userOwnsTweet[msg.sender][_id];
        uint index = indexOfTweetId[_id];
        uint lastIndex = userTweets[msg.sender].length - 1;
        Tweet memory lastTweet = userTweets[msg.sender][lastIndex];
        indexOfTweetId[_id] = index;
        delete indexOfTweetId[_id];
        userTweets[msg.sender][index] = lastTweet;
        userTweets[msg.sender].pop();
        emit TweetDeleted(_id);
    }

}