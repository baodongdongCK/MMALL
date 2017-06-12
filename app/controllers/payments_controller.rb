# frozen_string_literal: true

class PaymentsController < ApplicationController
  protect_from_forgery except: [:alipay_notify]

  before_action :auth_user, except: [:pay_notify]
  before_action :auth_request, only: %i[pay_return pay_notify]
  before_action :find_and_validate_payment_no, only: %i[pay_return pay_notify]

  def pay_notify
    do_payment
  end

  def pay_return
    do_payment
  end

  def success; end

  def failed; end

  def do_payment
    if @payment.is_success?
      redirect_to success_payment_path
    else
      if is_payment_success?
        @payment.do_success_payment! params
        redirect_to success_payments_path
      else
        @payment.do_failed_payment! params
        redirect_to failed_payments_path
      end
    end
  end

  def is_payment_success?
    %w[TRADE_SUCCESS TRADE_FINISHED].include?(params[:trade_status])
  end

  def auth_request
    unless build_is_request_from_alipay?(params)
      Rails.logger.info ''
      redirect_to failed_payments_path
    end

    unless build_is_request_sign_valid?(params)
      Rails.logger.info "PAYMENT DEBUG ALIPAY SIGN INVALID: #{params.to_hash}"
      redirect_to failed_payments_path
    end
  end

  def build_is_request_from_alipay?(result_options)
    return false if result_options[:notify_id].blank?
    body = RestClent.get ENV['ALIPAY_URL'] + '?' + {
      service: 'notify_verify',
      partner: ENV['ALIPAY_PID'],
      notify_id: result_options[:notify_id]
    }.to_query
    body == 'true'
  end

  def build_is_request_sign_valid?(result_options)
    options = result_options.to_hash
    options.extract!('controller', 'action', 'format')
    if options['sign_type'] == 'MD5'
      options['sign'] == build_generate_sign(options)
    elsif options['sign_type'] == 'RSA'
      build_rsa_verify?(build_sign_data(options.dup), options['sign'])
    end
  end

  def build_generate_sign(options)
    sign_data = build_sign_data(options.dup)
    if options['sign_type'] == 'MD5'
      Digest::MD5.hexdigest(sign_data + ENV['ALIPAY_MD5_SECRET'])
    elsif options['sign_type'] == 'RSA'
      build_rsa_sign(sign_data)
    end
  end

  def build_sign_data(data_hash)
    data_hash.delete_if { |k, v| k == 'sign_type' || k == 'sign' || v.blank? }
    data_hash.to_a.map { |x| x.join('=') }.sort.join('&')
  end

  # RSA 签名
  def build_rsa_sign(data)
    debugger
    private_key_path = Rails.root.to_s + '/config/.alipay_self_private'
    pri = OpenSSL::PKey::RSA.new(File.read(private_key_path))
    signature = Base64.encode64(pri.sign('sha1', data))
    signature
  end

  # RSA 验证
  def build_rsa_verify?(data, sign)
    public_key_path = Rails.root.to_s + '/config/.alipay_public'
    pub = OpenSSL::PKey::RSA.new(File.read(public_key_path))
    digester = OpenSSL::Digest::SHA1.new
    sign = Base64.decode64(sign)
    pub.verify(digester, sign, data)
  end

  def find_and_validate_payment_no
    @payment = Payment.find_by_payment_no params[:out_trade_no]
    unless @payment
      if is_payment_success?
        render text: '未找到您的订单号，但是已经支付'
        return
      else
        render text: '未找到您的订单号,同时您也没完成支付，请重新支付'
        return
      end
    end
  end

  def index
    @payment = current_user.payments.find_by(payment_no: params[:payment_no])
    # 支付宝接口需要申请
    @payment_url = build_payment_url
    @pay_options = build_request_options(@payment)
  end

  def generate_pay
    orders = current_user.orders.where(order_no: params[:order_nos].split(','))
    payment = Payment.create_from_orders!(current_user, orders)
    redirect_to payments_path(payment_no: payment.payment_no)
  end

  private

  def build_payment_url
    "#{ENV['ALIPAY_URL']}?_input_charset=utf-8"
  end

  def build_request_options(payment)
    pay_options = {
      'service' => 'create_direct_pay_by_user',
      'partner' => ENV['ALIPAY_PID'],
      'seller_id' => ENV['ALIPAY_PID'],
      'payment_type' => '1',
      'notify_url' => ENV['ALIPAY_NOTIFY_URL'],
      'return_url' => ENV['ALIPAY_RETURN_URL'],
      'anti_phishing_key' => '',
      'exter_invoke_ip' => '',
      'out_trade_no' => payment.payment_no,
      'subject' => '东东商城商品购买',
      'total_fee' => payment.total_money,
      'body' => '东东商城商品购买',
      '_input_charset' => 'utf-8',
      'sign_type' => 'MD5',
      'sign' => ''
    }
    pay_options['sign'] = build_generate_sign(pay_options)
    pay_options
  end
end
