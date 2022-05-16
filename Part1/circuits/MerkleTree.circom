pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    // The total number of leaves
    var total_leaves = 2**n;

    // The number of HashLeftRight components which will be used to hash the leaves
    var num_leaf_hashers = total_leaves / 2;

    // The number of HashLeftRight components which will be used to hash the output of the leaf hasher components
    var num_intermediate_hashers = num_leaf_hashers - 1;
    // The total number of hashers
    var num_hashers = total_leaves - 1;
    component hashers[num_hashers];


    for (var i=0; i < num_hashers; i++) {
        hashers[i] = HashLeftRight();
    }

    for (var i=0; i < num_leaf_hashers; i++){
        hashers[i].left <== leaves[i*2];
        hashers[i].right <== leaves[i*2+1];
    }
    var k = 0;
    for (var i=num_leaf_hashers; i<num_leaf_hashers + num_intermediate_hashers; i++) {
        hashers[i].left <== hashers[k*2].hash;
        hashers[i].right <== hashers[k*2+1].hash;
        k++;
    }
    // root hash value
    root <== hashers[num_hashers-1].hash;
}

template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== left;
    hasher.inputs[1] <== right;
    hash <== hasher.out;
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    // component poseidon = Poseidon(3);
    component selectors[n];
    component hashers[n];

    for (var i = 0; i < n; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
        selectors[i].in[1] <== path_elements[i];
        selectors[i].s <== path_index[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].out[0];
        hashers[i].right <== selectors[i].out[1];
    }

    root <== hashers[n - 1].hash;
}