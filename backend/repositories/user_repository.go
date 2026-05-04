package repositories

import (
	"log"
	"project/backend/models"
	"strings"

	"gorm.io/gorm"
)

type UserRepository struct {
	DB *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{DB: db}
}

func (r *UserRepository) Create(user *models.User) error {
	log.Printf("📝 Storing user in DB - Email: %s, Password (first 20 chars): %.20s..., Hash length: %d", user.Email, user.Password, len(user.Password))
	err := r.DB.Create(user).Error
	if err == nil {
		log.Printf("✅ User stored successfully: %s", user.Email)
	} else {
		log.Printf("❌ Failed to store user: %v", err)
	}
	return err
}

func (r *UserRepository) GetByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.DB.Where("email = ?", strings.ToLower(strings.TrimSpace(email))).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) GetByID(id uint) (*models.User, error) {
	var user models.User
	err := r.DB.First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Update(user *models.User) error {
	log.Printf("📝 Updating user in DB - Email: %s, ID: %d", user.Email, user.ID)
	err := r.DB.Save(user).Error
	if err == nil {
		log.Printf("✅ User updated successfully: %s", user.Email)
	} else {
		log.Printf("❌ Failed to update user: %v", err)
	}
	return err
}
