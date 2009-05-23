module LogicalDestroyable
  def self.included(base)
    base.named_scope(:active, {:conditions => {:deleted => false}})
  end

  def logical_destroy
    update_attribute(:deleted, true)
  end

  def recover
    update_attribute(:deleted, false)
  end
end

