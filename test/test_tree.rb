require 'helper'

class TestTree < MiniTest::Unit::TestCase

  def test_leaf_node_with_invalid_value
    assert_raises ArgumentError do
      LiabilityProof::Tree::LeafNode.new('', '', '')
    end
  end

  def test_leaf_node
    node = LiabilityProof::Tree::LeafNode.new('jan', BigDecimal.new('12.13'), '1234567890ABCDEF')

    assert_equal 'jan', node.user
    assert_equal BigDecimal.new('12.13'), node.sum
    assert_equal '1234567890ABCDEF', node.nonce
    assert_equal 64, node.hash.size
  end

  def test_interior_node
    left = LiabilityProof::Tree::LeafNode.new('jan', BigDecimal.new('12.13'), '')
    right = LiabilityProof::Tree::LeafNode.new('zw', BigDecimal.new('20.14'), '')

    node  = LiabilityProof::Tree::InternalNode.new left, right
    assert_equal left,  node.left
    assert_equal right, node.right

    sum  = (left.sum + right.sum).to_s('F')
    hash = LiabilityProof.sha256_base64 "#{sum}|#{left.hash}|#{right.hash}"
    assert_equal hash, node.hash
  end

  def test_tree_generation
    sum = accounts
      .map {|a| BigDecimal.new a['balance'] }
      .inject(0, &:+)

    assert_equal sum, tree.root.sum
  end

  def test_tree_generation_with_empty_accounts
    assert_raises ArgumentError do
      LiabilityProof::Tree.new []
    end
  end

  def test_tree_indices
    assert_equal [:left, :left, :left, :left, :left], tree.indices['jan']
    assert_equal [:right, :right], tree.indices['picasso']
  end

  def test_tree_partial_tree
    partial = tree.partial('jan')

    leaf_data = partial['left']['left']['left']['left']['left']['data']
    assert_equal 'jan', leaf_data['user']
    assert_equal '12.13', leaf_data['sum']
    assert_equal 32, leaf_data['nonce'].size
    assert_equal false, leaf_data.has_key?('hash')
    assert_equal true, leaf_data.has_key?('nonce')

    other_data = partial['left']['left']['left']['left']['right']['data']
    assert_nil other_data['user']
    assert_nil other_data['nonce']
  end

  def test_tree_partial_json
    assert_equal 'partial_tree', tree.partial_json('jan').keys.first
  end

  def test_tree_root_json
    assert_equal "27748.32", tree.root_json['root']['sum']
  end

  def test_tree_root_json_with_currency
    tree = LiabilityProof::Tree.new accounts, currency: 'CNY'
    assert_equal 'CNY', tree.root_json['currency']
  end

  private

  def tree
    @tree ||= LiabilityProof::Tree.new accounts
  end

end
