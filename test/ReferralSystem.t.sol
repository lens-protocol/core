// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/mocks/MockModule.sol';
import 'test/base/BaseTest.t.sol';

/**
 * Tests shared among all operations where the Lens V2 Referral System applies, e.g. act, quote, comment, mirror.
 */
contract ReferralSystemTest is BaseTest {
    TestAccount[] testAccounts;

    // function _setReferrers(uint256[] memory referrerProfileIds, uint256[] memory referrerPubIds) internal virtual;

    function _executeOperation(TestPublication memory target, TestPublication memory referralPub) internal virtual {
        uint256 testAccountId = testAccounts.length;
        TestAccount memory actor = _loadAccountAs(string.concat('TESTACCOUNT_', vm.toString(testAccountId)));
        testAccounts.push(actor);
        Types.PublicationActionParams memory actParams = _getDefaultPublicationActionParams();
        actParams.publicationActedProfileId = target.profileId;
        actParams.publicationActedId = target.pubId;
        actParams.actorProfileId = actor.profileId;
        actParams.referrerProfileIds = _toUint256Array(referralPub.profileId);
        actParams.referrerPubIds = _toUint256Array(referralPub.pubId);

        console.log('ACTING on %s, %s', vm.toString(target.profileId), vm.toString(target.pubId));
        console.log('    with referral: %s, %s', vm.toString(referralPub.profileId), vm.toString(referralPub.pubId));

        // TODO:
        // we do some action on target while passing reference as referral and expect it to be called,
        // so expectCall should check that the reference was passed as referral and it didn't revert.
        // vm.expectCall /* */();
        // TODO:
        // _executeOperation(target, referralPub);

        vm.prank(actor.owner);
        hub.act(actParams);
    }

    function setUp() public virtual override {
        super.setUp();
    }

    struct Tree {
        TestPublication post;
        TestPublication[] references;
        TestPublication[] mirrors;
    }

    // All references are V2 now
    function testV2References() public virtual {
        // for (uint256 commentQuoteFuzzBitmap = 0; commentQuoteFuzzBitmap < 32; commentQuoteFuzzBitmap++) {
        // Tree memory treeV2 = _createV2Tree(commentQuoteFuzzBitmap);
        // }

        Tree memory treeV2 = _createV2Tree(14);

        {
            // Target a post with quote/comment as referrals
            TestPublication memory target = treeV2.post;
            for (uint256 i = 0; i < treeV2.references.length; i++) {
                TestPublication memory referralPub = treeV2.references[i];
                _executeOperation(target, referralPub);
            }
        }

        {
            // Target a post with mirrors as referrals
            TestPublication memory target = treeV2.post;
            for (uint256 i = 0; i < treeV2.mirrors.length; i++) {
                TestPublication memory referralPub = treeV2.mirrors[i];
                _executeOperation(target, referralPub);
            }
        }

        {
            // Target as a quote/comment node and pass another quote/comments as referral
            for (uint256 i = 0; i < treeV2.references.length; i++) {
                TestPublication memory target = treeV2.references[i];
                for (uint256 j = 0; j < treeV2.references.length; j++) {
                    TestPublication memory referralPub = treeV2.references[j];
                    if (i == j) continue; // skip self
                    // vm.expectCall /* */();

                    _executeOperation(target, referralPub);
                }

                // // One special case is a post as referal for reference node
                // TestPublication memory referralPub = treeV2.post;
                // // vm.expectCall /* */();
                // _executeOperation(target, referralPub);
            }
        }

        // {
        //     // Target as a mirror node
        //     // A mirror cannot be a target - so we expect revert here
        //     for (uint256 i = 0; i < treeV2.mirrors.length; i++) {
        //         uint256 target = treeV2.mirrors[i];
        //         for (uint256 j = 0; i < treeV2.references.length; j++) {
        //             uint256 referencePub = treeV2.references[j];
        //             // vm.expectRevert /* */();
        //             _executeOperation(target, referencePub);
        //         }

        //         // One special case is a post as referal for mirror node
        //         uint256 referencePub = treeV2.post;
        //         // vm.expectRevert /* */();
        //         _executeOperation(target, referencePub);
        //     }
        // }
    }

    function _createV2Tree(uint256 commentQuoteFuzzBitmap) internal returns (Tree memory) {
        /*
            Post_1
            |
            |-- Comment/Quote_0 -- Mirror_0 (mirror of a direct reference)
            |        |
            |        |-- Comment/Quote_1 -- Mirror_1 (mirror of a 1st level reference)
            |                 |
            |                 |-- Comment/Quote_2 -- Mirror_2 (mirror of a 2nd level reference)
            |                           |
            |                           |-- Comment/Quote_3 -- Mirror_3 (mirror of a 3rd level reference)
            |
            |
            |-- Comment/Quote_4 -- Mirror_4 (a different branch)
            |
            |
            |-- Mirror_5 (direct post mirror)
        */

        //   Created POST: 2, 1
        //   Created COMMENT: (2, 1) <= (3, 1)
        //   Created MIRROR: (3, 1) <= (4, 1)
        //   Created QUOTE: (3, 1) <= (5, 1)
        //   Created MIRROR: (5, 1) <= (6, 1)
        //   Created QUOTE: (5, 1) <= (7, 1)
        //   Created MIRROR: (7, 1) <= (8, 1)
        //   Created QUOTE: (7, 1) <= (9, 1)
        //   Created MIRROR: (9, 1) <= (10, 1)
        //   Created COMMENT: (2, 1) <= (11, 1)
        //   Created MIRROR: (11, 1) <= (12, 1)
        //   Created MIRROR: (2, 1) <= (13, 1)
        //   ACTING on 2, 1
        //       with referral: 3, 1
        //   ACTING on 2, 1
        //       with referral: 5, 1
        //   ACTING on 2, 1
        //       with referral: 7, 1
        //   ACTING on 2, 1
        //       with referral: 9, 1
        //   ACTING on 2, 1
        //       with referral: 11, 1
        //   ACTING on 2, 1
        //       with referral: 4, 1
        //   ACTING on 2, 1
        //       with referral: 6, 1
        //   ACTING on 2, 1
        //       with referral: 8, 1
        //   ACTING on 2, 1
        //       with referral: 10, 1
        //   ACTING on 2, 1
        //       with referral: 12, 1
        //   ACTING on 2, 1
        //       with referral: 13, 1
        //   ACTING on 3, 1
        //       with referral: 5, 1
        //   ACTING on 3, 1
        //       with referral: 7, 1
        //   ACTING on 3, 1
        //       with referral: 9, 1
        //   ACTING on 3, 1
        //       with referral: 11, 1

        Tree memory tree;
        tree.references = new TestPublication[](5);
        tree.mirrors = new TestPublication[](6);

        tree.post = post();

        tree.references[0] = _commentOrQuote(tree.post, commentQuoteFuzzBitmap, 0);
        tree.mirrors[0] = mirror(tree.references[0]);
        tree.references[1] = _commentOrQuote(tree.references[0], commentQuoteFuzzBitmap, 1);
        tree.mirrors[1] = mirror(tree.references[1]);
        tree.references[2] = _commentOrQuote(tree.references[1], commentQuoteFuzzBitmap, 2);
        tree.mirrors[2] = mirror(tree.references[2]);
        tree.references[3] = _commentOrQuote(tree.references[2], commentQuoteFuzzBitmap, 3);
        tree.mirrors[3] = mirror(tree.references[3]);

        tree.references[4] = _commentOrQuote(tree.post, commentQuoteFuzzBitmap, 4);
        tree.mirrors[4] = mirror(tree.references[4]);

        tree.mirrors[5] = mirror(tree.post);

        return tree;
    }

    // function _createV1ContaminatedTree(uint256 commentQuoteFuzzBitmap) internal returns (Tree memory) {
    //     /*
    //         Post_1 (V1)
    //         |
    //         |-- Comment/Quote_0 -- Mirror_0 (mirror of a direct reference)
    //         |        |
    //         |        |-- Comment/Quote_1 -- Mirror_1 (mirror of a 1st level reference)
    //         |                 |
    //         |                 |-- Comment/Quote_2 -- Mirror_2 (mirror of a 2nd level reference)
    //         |                           |
    //         |                           |-- Comment/Quote_3 -- Mirror_3 (mirror of a 3rd level reference)
    //         |
    //         |
    //         |-- Comment/Quote_4 -- Mirror_4 (a different branch)
    //         |
    //         |
    //         |-- Mirror_5 (direct post mirror)
    //     */

    //     Tree memory tree;
    //     tree.references = new uint256[](5);
    //     tree.mirrors = new uint256[](6);

    //     tree.post = post();
    //     _toV1Post(tree.post);

    //     tree.references[0] = _commentOrQuote(tree.post, commentQuoteFuzzBitmap, 0);
    //     tree.mirrors[0] = mirror(tree.references[0]);
    //     tree.references[1] = _commentOrQuote(tree.references[0], commentQuoteFuzzBitmap, 1);
    //     tree.mirrors[1] = mirror(tree.references[1]);
    //     tree.references[2] = _commentOrQuote(tree.references[1], commentQuoteFuzzBitmap, 2);
    //     tree.mirrors[2] = mirror(tree.references[2]);
    //     tree.references[3] = _commentOrQuote(tree.references[2], commentQuoteFuzzBitmap, 3);
    //     tree.mirrors[3] = mirror(tree.references[3]);

    //     tree.references[4] = _commentOrQuote(tree.post, commentQuoteFuzzBitmap, 4);
    //     tree.mirrors[4] = mirror(tree.references[4]);

    //     tree.mirrors[5] = mirror(tree.post);

    //     return tree;
    // }

    function _commentOrQuote(
        TestPublication memory testPub,
        uint256 commentQuoteFuzzBitmap,
        uint256 commentQuoteIndex
    ) internal returns (TestPublication memory) {
        uint256 commentQuoteFuzz = (commentQuoteFuzzBitmap >> (commentQuoteIndex)) & 1;
        if (commentQuoteFuzz == 0) {
            return comment(testPub);
        } else {
            return quote(testPub);
        }
    }

    function _toV1Post(TestPublication memory testPub) internal {
        // TODO
    }

    function post() internal returns (TestPublication memory) {
        uint256 testAccountId = testAccounts.length;
        TestAccount memory publisher = _loadAccountAs(string.concat('TESTACCOUNT_', vm.toString(testAccountId)));
        testAccounts.push(publisher);
        Types.PostParams memory postParams = _getDefaultPostParams();
        postParams.profileId = publisher.profileId;

        vm.prank(publisher.owner);
        uint256 pubId = hub.post(postParams);

        console.log('Created POST: %s, %s', publisher.profileId, pubId);
        return TestPublication(publisher.profileId, pubId);
    }

    function mirror(TestPublication memory testPub) internal returns (TestPublication memory) {
        uint256 testAccountId = testAccounts.length;
        TestAccount memory publisher = _loadAccountAs(string.concat('TESTACCOUNT_', vm.toString(testAccountId)));
        testAccounts.push(publisher);
        Types.MirrorParams memory mirrorParams = _getDefaultMirrorParams();
        mirrorParams.profileId = publisher.profileId;
        mirrorParams.pointedPubId = testPub.pubId;
        mirrorParams.pointedProfileId = testPub.profileId;

        vm.prank(publisher.owner);
        uint256 pubId = hub.mirror(mirrorParams);

        console.log(
            'Created MIRROR: (%s) <= (%s)',
            string.concat(vm.toString(testPub.profileId), ', ', vm.toString(testPub.pubId)),
            string.concat(vm.toString(publisher.profileId), ', ', vm.toString(pubId))
        );

        return TestPublication(publisher.profileId, pubId);
    }

    function comment(TestPublication memory testPub) internal returns (TestPublication memory) {
        uint256 testAccountId = testAccounts.length;
        TestAccount memory publisher = _loadAccountAs(string.concat('TESTACCOUNT_', vm.toString(testAccountId)));
        testAccounts.push(publisher);
        Types.CommentParams memory commentParams = _getDefaultCommentParams();

        commentParams.profileId = publisher.profileId;
        commentParams.pointedPubId = testPub.pubId;
        commentParams.pointedProfileId = testPub.profileId;

        vm.prank(publisher.owner);
        uint256 pubId = hub.comment(commentParams);

        console.log(
            'Created COMMENT: (%s) <= (%s)',
            string.concat(vm.toString(testPub.profileId), ', ', vm.toString(testPub.pubId)),
            string.concat(vm.toString(publisher.profileId), ', ', vm.toString(pubId))
        );

        return TestPublication(publisher.profileId, pubId);
    }

    function quote(TestPublication memory testPub) internal returns (TestPublication memory) {
        uint256 testAccountId = testAccounts.length;
        TestAccount memory publisher = _loadAccountAs(string.concat('TESTACCOUNT_', vm.toString(testAccountId)));
        testAccounts.push(publisher);
        Types.QuoteParams memory quoteParams = _getDefaultQuoteParams();

        quoteParams.profileId = publisher.profileId;
        quoteParams.pointedPubId = testPub.pubId;
        quoteParams.pointedProfileId = testPub.profileId;

        vm.prank(publisher.owner);
        uint256 pubId = hub.quote(quoteParams);

        console.log(
            'Created QUOTE: (%s) <= (%s)',
            string.concat(vm.toString(testPub.profileId), ', ', vm.toString(testPub.pubId)),
            string.concat(vm.toString(publisher.profileId), ', ', vm.toString(pubId))
        );

        return TestPublication(publisher.profileId, pubId);
    }

    ////// setup////
    /// create a big tree with all possible situations (V2 posts)
    /// We can use some custom data structure to simplify the tree handling, or just rely on "pointedTo" in pubs.
    ///
    ////// function replaceV1(depth) ///
    /// function that will convert a given depth of the V2 tree into V1 (starting from the root Post)
    ///
    ////// function testReferralsWorkV2() ///
    /// a function that takes each node of the V2 tree as target (except mirrors), and permutates with all possible referrers
    /// (or makes an array of all other nodes as referrers and passes then all together).
    /// Then it checks that the referral system works as expected (i.e. modules are called with the same array of referrals).
    ///
    ////// function testReferralsV1() ///
    /// a function that takes a V2 tree, and converts it to V1 tree gradually, starting with root Post, then level 1 from it, level 2, etc.
    /// At each step, it checks that you can only refer the direct link (pointing to), as this is the only thing possible in V1
    /// It does this by picking a random node from the tree as target, and then picking the rest of the nodes as referrers,
    /// and expecting them to be passed or failed, depending if they're direct or complex.
    ///

    // Negatives

    function testCannotExecuteOperationIf_ReferralProfileIdsPassedQty_DiffersFromPubIdsQty() public {
        // TODO - Errors.ArrayMismatch();
    }

    function testCannotPass_APublicationDoneByItself_AsReferrer() public {
        // TODO - Errors.InvalidReferrer();
    }

    function testCannotPass_Itself_AsReferrer() public {
        // TODO - Errors.InvalidReferrer();
    }

    function testCannotPass_UnexistentProfile_AsReferrer() public {
        // TODO - Errors.InvalidReferrer();
    }

    function testCannotPass_UnexistentPublication_AsReferrer() public {
        // TODO
    }

    function testCannotPass_AMirror_AsReferrer_IfNotPointingToTheTargetPublication() public {
        // TODO
    }

    function testCannotPass_AComment_AsReferrer_IfNotPointingToTheTargetPublication() public {
        // TODO
    }

    // Scenarios

    // This test might fail at some point when we check for duplicates!
    function testPassingDuplicatedReferralsIsAllowed() public {
        // TODO
    }
}
