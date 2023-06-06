// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/mocks/MockModule.sol';
import 'test/base/BaseTest.t.sol';

/**
 * Tests shared among all operations where the Lens V2 Referral System applies, e.g. act, quote, comment, mirror.
 */
abstract contract ReferralSystemTest is BaseTest {
    TestAccount publisher;
    TestAccount anotherPublisher;

    function _setReferrers(uint256[] memory referrerProfileIds, uint256[] memory referrerPubIds) internal virtual;

    function _executeOperation(uint256 signerPk, uint256 publisherProfileId) internal virtual returns (uint256);

    function setUp() public virtual override {
        super.setUp();
        publisher = _loadAccountAs('PUBLISHER');
        anotherPublisher = _loadAccountAs('ANOTHER_PUBLISHER');
    }

    struct Tree {
        uint256 post;
        uint256[] references;
        uint256[] mirrors;
    }

    // function testV2References(uint256 commentQuoteFuzzBitmap) public {
    //     commentQuoteFuzzBitmap = bound(commentQuoteFuzzBitmap, 0, 31);
    //     Tree memory treeV2 = _createV2Tree(commentQuoteFuzzBitmap);

    //     uint256 target = treeV2.post;
    //     // for (uint256 reference=0; i<treeV2.references.length)
    // }

    // function _createV2Tree(uint256 commentQuoteFuzzBitmap) internal returns (Tree memory) {
    //     /*
    //         Post_1
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
    // }

    // function _commentOrQuote(
    //     uint256 pubId,
    //     uint256 commentQuoteFuzzBitmap,
    //     uint256 commentQuoteIndex
    // ) internal returns (uint256) {
    //     uint256 commentQuoteFuzz = (commentQuoteFuzzBitmap >> (commentQuoteIndex)) & 1;
    //     if (commentQuoteFuzz == 0) {
    //         return comment(pubId);
    //     } else {
    //         return quote(pubId);
    //     }
    // }

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
