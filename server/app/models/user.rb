class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Authority::UserAbilities
  include Authority::Abilities

  has_and_belongs_to_many :grids
  has_many :access_tokens, dependent: :delete
  has_many :audit_logs
  has_and_belongs_to_many :roles

  belongs_to :parent, class_name: "User", inverse_of: :children
  has_many :children, class_name: "User", inverse_of: :parent

  field :email, type: String
  field :name,  type: String
  field :external_id, type: String
  field :member_of, type: Array
  field :invite_code, type: String

  validates :email,
            uniqueness: true,
            presence: true
  validates :email,
            format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i },
            unless: :is_local_admin_or_has_parent?

  validates :external_id, uniqueness: { allow_nil: true }
  validates :invite_code, uniqueness: { allow_nil: true }

  index({ email: 1 }, { unique: true })
  index({ external_id: 1 }, { sparse: true })
  index({ invite_code: 1}, { sparse: true })

  # Fake setter. When true, an invite code will be generated
  def with_invite=(boolean)
    if boolean
      self[:invite_code] = SecureRandom.hex(6)
    end
  end

  def is_local_admin_or_has_parent?
    is_local_admin? || !self[:parent].nil?
  end

  def is_local_admin?
    self[:email] == 'admin'
  end

  def member_of?(org_name)
    return false if self.member_of.nil?
    return false if self.member_of.empty?
    self.member_of.include?(org_name)
  end

  ##
  # @return [Mongoid::Criteria]
  def accessible_grids
    if self.master_admin?
      Grid.all
    else
      self.grids
    end
  end

  ##
  # @param [String] role
  def in_role?(role)
    self.roles.where(name: role).exists?
  end

  def master_admin?
    self.email == 'admin' || self.in_role?(Role::MASTER_ADMIN_ROLE)
  end

  def grid_admin?(grid)
    self.master_admin? || (self.in_role?(Role::GRID_ADMIN_ROLE) && self.grids.include?(grid))
  end
end
