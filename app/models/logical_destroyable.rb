module LogicalDestroyable
  def self.included(base)
    base.named_scope(:active, {:conditions => {:deleted => false}})
  end

  def logical_destroy
    before_logical_destroy
    update_attribute(:deleted, true)
    after_logical_destroy
  end

  def recover
    update_attribute(:deleted, false)
  end

  def before_logical_destroy;end
  def after_logical_destroy;end
end
