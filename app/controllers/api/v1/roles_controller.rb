# frozen_string_literal: true

module Api
  module V1
    class RolesController < ApplicationController
      before_action :set_role, only: [:show, :update, :destroy]

      # GET /api/v1/roles
      def index
        @roles = Role.all
        render json: @roles
      end

      # GET /api/v1/roles/1
      def show
        render json: @role
      end

      # POST /api/v1/roles
      def create
        @role = Role.new(role_params)

        if @role.save
          render json: @role, status: :created
        else
          render json: @role.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/roles/1
      def update
        if @role.default?
          render json: { error: 'Cannot modify a default role' }, status: :forbidden
        elsif @role.update(role_params)
          render json: @role
        else
          render json: @role.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/roles/1
      def destroy
        if @role.destroy
          head :no_content
        else
          render json: { error: @role.errors.full_messages.first || 'Unable to delete role' }, 
                 status: :unprocessable_entity
        end
      end

      private

      def set_role
        @role = Role.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Role not found' }, status: :not_found
      end

      def role_params
        params.require(:role).permit(:name)
      end
    end
  end
end
